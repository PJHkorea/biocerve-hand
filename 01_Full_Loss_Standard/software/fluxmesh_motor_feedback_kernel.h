/**
 * @file fluxmesh_motor_feedback_kernel.h
 * @brief 소용돌이 변위 기반 5지 모터 매핑 및 전류 과부하 자율 사멸 피드백 루프
 * 
 * [주의] 컴파일러 최적화 플래그로 -Ofast, -ffast-math 절대 사용 금지! (-O2/-O3 필수)
 */

#ifndef FLUXMESH_MOTOR_FEEDBACK_KERNEL_H
#define FLUXMESH_MOTOR_FEEDBACK_KERNEL_H

#include <cmath>

// --- [하드웨어 및 손가락 인덱스 정의] ---
#define NUM_FINGERS          5
#define MOTOR_PWM_MIN        1000  // 서보 모터 최소 펄스 폭 (1.0ms - 완전히 편 상태)
#define MOTOR_PWM_MAX        2000  // 서보 모터 최대 펄스 폭 (2.0ms - 완전히 쥔 상태)

// 전류 과부하 및 사멸 임계치 (하드웨어 사양에 맞게 튜닝)
#define CURRENT_CRITICAL_MA  1200.0f // 사멸을 유도할 치명적 과부하 전류 (1.2A)
#define OVERLOAD_STRIKE_MAX  8        // 연속 과부하 감지 시 세포 사멸 트리거 카운트

enum FingerIndex {
    FIN_THUMB = 0, // 엄지
    FIN_INDEX = 1, // 검지
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
    
    // 전류 피드백 및 자가 감시 레이어
    volatile float current_ma;     // 실시간 측정된 모터 소비 전류 (밀리어페어)
    volatile int   overload_strikes;// 과부하 누적 스트라이크 카운트
    volatile bool  is_dead;        // 특정 손가락의 영구 사멸 및 링크 절단 여부
} FingerMotorState;

/**
 * @brief 5개 손가락 외골격 모터 상태 초기화
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
        fingers[i].current_ma = 0.0f;
        fingers[i].overload_strikes = 0;
        fingers[i].is_dead = false;
    }
}

/**
 * @brief 전류 피드백을 스캔하여 과부하 시 로컬 반사 신경단 사멸(Apoptosis) 유도
 * @details 이 수식은 파데 유리함수 도메인 축소와 Joseph Form 구조의 안전 마진을 모사합니다.
 */
void fluxmesh_motor_feedback_scan(FingerMotorState* fingers, float* raw_current_sensors) {
    for (int i = 0; i < NUM_FINGERS; i++) {
        // [GUARD 1] 센서 단선 및 하드웨어 폭주에 의한 NaN 유입 즉시 차단
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
                fingers[i].is_dead = true; // 세포 사멸 (Apoptosis)
            }
        } else {
            // 점진적 자가 치유 및 마진 회복 (오진 방지용 감쇄 수식)
            if (fingers[i].overload_strikes > 0) {
                fingers[i].overload_strikes--;
            }
        }
    }
}

/**
 * @brief 2층 메쉬 출력 소용돌이 변위를 5개 손가락 PWM 신호로 사산(Flattening) 매핑
 * @param dy 2층 메쉬 코어에서 계산된 Y축 공간 격차 흐름 벡터 (0.0f ~ 1.0f 부근 가동)
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

    // 1단계: 살아있는 손가락들의 시너지 가중치 합산 (사멸된 손가락 에너지 우회 준비)
    for (int i = 0; i < NUM_FINGERS; i++) {
        if (!fingers[i].is_dead) {
            alive_synergy_pool += fingers[i].synergy_weight;
        }
    }

    // [GUARD 3] 만약 모든 손가락이 사멸(완전 고장)했다면 즉시 시스템 셧다운
    if (alive_synergy_pool <= 0.001f) {
        for (int i = 0; i < NUM_FINGERS; i++) out_pwms[i] = MOTOR_PWM_MIN; // 안전 전원 강제 해제
        return;
    }

    // 2단계: 소용돌이 에너지를 살아있는 노드로 사선 우회(Rerouting) 및 PWM 변환
    for (int i = 0; i < NUM_FINGERS; i++) {
        if (fingers[i].is_dead) {
            // 이미 사멸된 손가락은 물리적으로 에너지를 공급하지 않음 (이전 파지 상태 고정 또는 복귀)
            out_pwms[i] = MOTOR_PWM_MIN; 
            continue;
        }

        // 핵심 수식: 전체 에너지 풀에서 사망한 노드의 지분을 배제하고 남은 노드로 동적 분배 (우회장 발현)
        // 이 수식 덕분에 특정 손가락이 물체에 부딪혀 죽으면, 남은 손가락들이 더 강하고 유기적으로 감싸 쥐게 됩니다.
        float dynamic_allocation = (fingers[i].synergy_weight / alive_synergy_pool) * compressed_dy;

        // 0.0f ~ 1.0f 범위로 클리핑 보호벽 가동
        if (dynamic_allocation < 0.0f) dynamic_allocation = 0.0f;
        if (dynamic_allocation > 1.0f) dynamic_allocation = 1.0f;

        // 물리적 서보 모터 PWM 레인지로 최종 변환 및 Joseph Form 스케일 가드
        float mix_factor = dynamic_allocation * dynamic_allocation; // 비선형 소용돌이 감각 가속
        out_pwms[i] = (int)(MOTOR_PWM_MIN + (MOTOR_PWM_MAX - MOTOR_PWM_MIN) * mix_factor);
    }
}

#endif // FLUXMESH_MOTOR_FEEDBACK_KERNEL_H
