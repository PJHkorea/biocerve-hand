/**
 * @file fluxmesh_motor_feedback_kernel.h
 * @brief 🌊 BioCerve-Hand: 소용돌이 변위 기반 5지 모터 매핑 및 하이브리드 미러링 제어 커널 (v2.5)
 * 
 * [주의] 컴파일러 최적화 플래그로 -Ofast, -ffast-math 절대 사용 금지! (-O2/-O3 필수)
 */

#ifndef FLUXMESH_MOTOR_FEEDBACK_KERNEL_H
#define FLUXMESH_MOTOR_FEEDBACK_KERNEL_H

#include <cmath>

// =================================================================
// [하드웨어 및 손가락 인덱스 정의]
// =================================================================
#define NUM_FINGERS          5
#define MOTOR_PWM_MIN        1000  // 서보 모터 최소 펄스 폭 (1.0ms - 완전히 편 상태)
#define MOTOR_PWM_MAX        2000  // 서보 모터 최대 펄스 폭 (2.0ms - 완전히 쥔 상태)

// 전류 과부하 및 사멸 임계치 (하드웨어 사양에 맞게 튜닝)
#define CURRENT_CRITICAL_MA  1200.0f // 사멸을 유도할 치명적 과부하 전류 (1.2A)
#define OVERLOAD_STRIKE_MAX  8        // 연속 과부하 감지 시 세포 사멸 트리거 카운트

enum FingerIndex {
    FIN_THUMB  = 0, // 엄지
    FIN_INDEX  = 1, // 검지
    FIN_MIDDLE = 2, // 중지
    FIN_RING   = 3, // 약지
    FIN_PINKY  = 4  // 새끼
};

/**
 * @struct FingerMotorState
 * @brief 각 손가락 외골격 모터의 물리적 상태 및 생체 신뢰도 보존 구조체
 */
typedef struct {
    int      pin_pwm;             // MCU 물리적 PWM 출력 핀 번호
    float    synergy_weight;      // 인간 손 특유의 연동 거동(Synergy) 분배 가중치
    
    // 3차 업그레이드: 하이브리드 일부 소실 환자 마스킹 및 미러링 레지스터 주입
    int      finger_status;       // 🛡️ 1: 소실(의수 텐던 구동), 0: 생체 존치 (손바닥 관통 홀 우회)
    float    live_flex_input;     // 👁️ 생체 존치 손가락에 부착된 굽힘 센서의 실시간 각도 (0 ~ 90)

    // 전류 피드백 및 자가 감시 레이어
    volatile float current_ma;     // 실시간 측정된 모터 소비 전류 (밀리어페어)
    volatile int   overload_strikes;// 과부하 누적 스트라이크 카운트
    volatile bool  is_dead;        // 특정 손가락의 영구 사멸 및 링크 절단 여부
} FingerMotorState;

// 3차 업그레이드: cpp 메인 파이프라인에서 참조할 수 있도록 전역 가운터 실장 바인딩
extern FingerMotorState my_bio_fingers[NUM_FINGERS];

/**
 * @brief 5개 손가락 외골격 모터 상태 및 하이브리드 프로파일 초기화
 */
void fluxmesh_motor_init(FingerMotorState* fingers) {
    // 실제 손의 해부학적 해부 구도(Synergy Weight)를 반영한 분배 계수
    // 엄지와 검지가 파지력의 핵심이므로 가중치를 높게 배정합니다.
    fingers[FIN_THUMB].synergy_weight  = 1.20f;
    fingers[FIN_INDEX].synergy_weight  = 1.10f;
    fingers[FIN_MIDDLE].synergy_weight = 0.95f;
    fingers[FIN_RING].synergy_weight   = 0.85f;
    fingers[FIN_PINKY].synergy_weight  = 0.75f;

    for(int i = 0; i < NUM_FINGERS; i++) {
        // 3차 업그레이드: 기본 프로파일은 손 전체 소실 표준(1)으로 세팅
        // (일부 소실 환자 포팅 시 메인 진입 전 원하는 손가락 주소의 상태를 0으로 강제 마스킹)
        fingers[i].finger_status    = 1; 
        fingers[i].live_flex_input  = 0.0f;
        
        fingers[i].current_ma       = 0.0f;
        fingers[i].overload_strikes = 0;
        fingers[i].is_dead          = false;
    }
}

/**
 * @brief 전류 피드백을 스캔하여 과부하 시 로컬 반사 신경단 사멸(Apoptosis) 유도
 * @details 이 수식은 파데 유리함수 도메인 축소와 Joseph Form 구조의 안전 마진을 모사합니다.
 */
void fluxmesh_motor_feedback_scan(FingerMotorState* fingers, float* raw_current_sensors) {
    for (int i = 0; i < NUM_FINGERS; i++) {
        // [GUARD 1-1] 3차 업그레이드: 생체 존치 손가락(Status 0)은 모터 피드백 루프 연산에서 원천 제외
        // 기계적 액추에이터가 존재하지 않으므로 전류 스캔 및 억울한 사멸(Apoptosis)을 철저히 방어
        if (fingers[i].finger_status == 0) {
            fingers[i].current_ma = 0.0f;
            fingers[i].overload_strikes = 0;
            fingers[i].is_dead = false;
            continue;
        }

        // [GUARD 1-2] 센서 단선 및 하드웨어 폭주에 의한 NaN 유입 즉시 차단
        if (raw_current_sensors[i] != raw_current_sensors[i]) { // IEEE 754 NaN 체크
            fingers[i].is_dead = true;
            fingers[i].current_ma = -99.0f; // 거부 신호 마킹
            continue;
        }

        if (fingers[i].is_dead) continue;

        // 실시간 전류값 업데이트
        fingers[i].current_ma = raw_current_sensors[i];

        // 과부하 임계치 판정 (물체에 걸려 텐던이 더 이상 당겨지지 않을 때)
        if (fingers[i].current_ma >= CURRENT_CRITICAL_MA) {
            fingers[i].overload_strikes++;
            
            // 연속 스트라이크 누적 시 해당 손가락 반사 노드 사멸 트리거
            if (fingers[i].overload_strikes >= OVERLOAD_STRIKE_MAX) {
                fingers[i].is_dead = true; // 세포 사멸 (Apoptosis) 집행
            }
        } else {
            // 1차 청사진 자가 치유 사상: 점진적 자가 치유 및 마진 회복 (오진 방지용 감쇄 수식)
            if (fingers[i].overload_strikes > 0) {
                fingers[i].overload_strikes--;
            }
        }
    }
}


/**
 * @brief 2층 메쉬 출력 소용돌이 변위 및 생체 미러링 신호를 5개 손가락 PWM 신호로 사산(Flattening) 매핑
 * @param dy 2층 메쉬 코어에서 계산된 축 공간 격차 흐름 벡터 (0.0f ~ 1.0f 부근 가동)
 * @param out_pwms 최종 계산된 MCU 출력용 PWM 제어 값 배열 (밀리초 단위 매핑)
 */
void fluxmesh_motor_mapping_execute(FingerMotorState* fingers, float dy, int* out_pwms) {
    // [GUARD 2] 입력 벡터의 무결성 검증 (메쉬 가속 엔진 다운스트림 폭주 방지)
    if (dy != dy || std::isinf(dy)) {
        dy = 0.0f; // Failsafe 강제 영점 조절
    }

    // 소용돌이 감쇄 도메인 수축 계수 (기하학적 압축용 파데 분모 트릭 적용)
    float denominator = 1.0f + std::abs(dy);
    float compressed_dy = dy / denominator; // 사칙연산 기반 완만 곡선 가속 (-1.0f ~ 1.0f 바운더리 보호)

    float alive_synergy_pool = 0.0f;
    float master_mirror_angle = 0.0f;
    bool  has_active_mirror = false;

    // ── 1단계: 🛡️ [하이브리드 미러링] 생체 손가락(Status 0)의 굽힘 센서에서 마스터 궤적 획득 ──
    for (int i = 0; i < NUM_FINGERS; i++) {
        if (fingers[i].finger_status == 0) {
            // 잔존하는 정상 생체 손가락 중 가동 각도가 가장 큰 신호를 앵커 마스터 각도로 획득
            if (fingers[i].live_flex_input > master_mirror_angle) {
                master_mirror_angle = fingers[i].live_flex_input;
                has_active_mirror = true;
            }
        }
    }

    // ── 2단계: 🌊 [사선 우회장 준비] 살아있는 '의수 구동' 손가락들의 시너지 가중치 합산 ──
    for (int i = 0; i < NUM_FINGERS; i++) {
        // 생체 손가락과 이미 전류 과부하로 사멸한 의수 마디는 모터 가중치 계산에서 제외
        if (fingers[i].finger_status == 1 && !fingers[i].is_dead) {
            alive_synergy_pool += fingers[i].synergy_weight;
        }
    }

    // [GUARD 3] 만약 모든 구동용 기계 손가락이 사멸(완전 고장)했다면 즉시 시스템 셧다운 락업
    // (이때 생체 손가락 관통 자리는 구멍 형태이므로 환자 본인의 힘으로 자유 주행 지속 가능)
    if (alive_synergy_pool <= 0.001f) {
        for (int i = 0; i < NUM_FINGERS; i++) {
            if (fingers[i].finger_status == 1) {
                out_pwms[i] = MOTOR_PWM_MIN; // 기계 마디만 안전 전원 강제 해제
            }
        }
        return;
    }

    // ── 3단계: 소용돌이 에너지 및 생체 미러링 궤적을 살아있는 기계 노드로 동적 분배 ──
    for (int i = 0; i < NUM_FINGERS; i++) {
        // [하이브리드 패스] 생체 손가락 자리는 기계식 모터가 없으므로 출력 신호를 완전히 인가하지 않음
        if (fingers[i].finger_status == 0) {
            out_pwms[i] = MOTOR_PWM_MIN; // 안전 기본값 고정 (물리 구멍으로 대체)
            continue;
        }

        if (fingers[i].is_dead) {
            // 이미 전류 사멸된 손가락은 물리적으로 전원을 빼서 Wedge-Lock 하드웨어 스토퍼 잠금 유도
            out_pwms[i] = MOTOR_PWM_MIN; 
            continue;
        }

        // 핵심 수식: 전체 에너지 풀에서 사망한 노드 및 생체 노드의 지분을 배제하고 남은 의수 노드로 동적 분배 (우회장 발현)
        float dynamic_allocation = 0.0f;
        
        if (has_active_mirror) {
            // 🎯 [생체 미러링 복사 모드]: 환자가 생체 손가락을 움직이면 의수가 그 각도를 실시간 추적
            // 0~90도 센서 입력을 0.0f ~ 1.0f 믹싱 팩터 레인지로 정밀 환산 매핑
            float normalized_mirror = master_mirror_angle / 90.0f;
            dynamic_allocation = (fingers[i].synergy_weight / alive_synergy_pool) * normalized_mirror;
        } else {
            // [전완근 글로벌 전위 모드]: 손 전체 소실 표준 트랙 구동
            dynamic_allocation = (fingers[i].synergy_weight / alive_synergy_pool) * compressed_dy;
        }

        // 0.0f ~ 1.0f 범위로 수치 해석적 클리핑 보호벽 가동
        if (dynamic_allocation < 0.0f) dynamic_allocation = 0.0f;
        if (dynamic_allocation > 1.0f) dynamic_allocation = 1.0f;

        // 물리적 서보 모터 PWM 레인지로 최종 변환 및 비선형 감각 가속
        float mix_factor = dynamic_allocation * dynamic_allocation; 
        out_pwms[i] = (int)(MOTOR_PWM_MIN + (MOTOR_PWM_MAX - MOTOR_PWM_MIN) * mix_factor);
    }
}

// 3차 업그레이드 마감: 외부 cpp 파일 바인딩을 위한 전역 변수 메모리 실장 선언
FingerMotorState my_bio_fingers[NUM_FINGERS];

#endif // FLUXMESH_MOTOR_FEEDBACK_KERNEL_H

