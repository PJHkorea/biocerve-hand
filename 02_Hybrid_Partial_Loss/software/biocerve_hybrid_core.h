/**
 * @file biocerve_hybrid_core.h
 * @brief 🌊 BioCerve-Hand: Hybrid Mirroring & Adaptive Synergy Allocation Kernel (v2.5)
 * License: GNU General Public License v3.0 (GPLv3)
 * 
 * [컴파일러 절대 준수 규칙]
 * -ffast-math 및 -Ofast 사용 절대 금지! 
 * Joseph Form 오차 실드 및 수치 방어벽(NaN Guard)의 무단 누락(DCE)을 방지하기 위해 
 * 반드시 컴파일 옵션으로 '-O2' 혹은 '-O3'만 사용하십시오.
 */

#ifndef BIOCERVE_HYBRID_CORE_H
#define BIOCERVE_HYBRID_CORE_H

#include <stdint.h>
#include <stdbool.h>
#include <math.h>

// 하이브리드 5지 규격 명세 정의
#define HYBRID_FINGERS       5
#define MOTOR_PWM_MIN        1000  // 서보 최소 펄스 폭 (1.0ms - 전력 전단 해제 / 수동 락인)
#define MOTOR_PWM_MAX        2000  // 서보 최대 펄스 폭 (2.0ms)
#define CURRENT_CRITICAL_MA  1200.0f // 세포 사멸을 유도할 과부하 임계 전류 (1.2A)
#define OVERLOAD_STRIKE_MAX  8        // 연속 과부하 타격 인내 임계치

enum HybridFingerIndex {
    H_THUMB  = 0, // 엄지
    H_INDEX  = 1, // 검지
    H_MIDDLE = 2, // 중지
    H_RING   = 3, // 약지
    H_PINKY  = 4  // 새끼
};

/**
 * @struct HybridFingerNode
 * @brief 하이브리드 5지 독립 상태 제어 컨테이너 및 생체 신뢰도 보존 구조체
 */
typedef struct {
    uint8_t  finger_id;       /**< 0:엄지, 1:검지, 2:중지, 3:약지, 4:새끼 */
    int      finger_status;   /**< 🛡️ 1: 소실(의수 텐던 구동), 0: 생체 존치 (손바닥 관통 홀) */
    float    synergy_weight;  /**< 협응 시너지 풀 내 해부학적 고유 가중치 */
    
    // 실시간 피드백 및 트래킹 레지스터
    float    current_pos;     /**< 의수 모터 현재 위치 */
    float    target_pos;      /**< 의수 모터 최종 연동 목표 위치 명령 (0 ~ 90도) */
    float    feedback_current;/**< 실시간 전류 센서 피드백 (mA) */
    float    live_flex_input; /**< 👁️ 생체 존치 손가락에 부착된 굽힘 센서 실시간 각도 (0 ~ 90) */
    
    // 안전 방어벽 레지스터 (Joseph Form Shield)
    float    p00;             /**< 오차 공분산 신뢰도 필터 수치 실드 */
    uint32_t strike_count;    /**< 연속 고전류 노이즈 타격 카운터 */
    volatile bool is_dead;    /**< 과부하로 인한 세포 사멸(Apoptosis) 집행 플래그 */
} HybridFingerNode;

/**
 * @brief 파데 [1/1] 유리함수 도메인 압축 (Pade Rational Function)
 * 초월함수 exp() 호출을 배제하여 임베디드 단에서 원클럭 최단 가속 연산 보장
 */
static inline float biocerve_hybrid_pade(float dy) {
    float abs_dy = (dy < 0.0f) ? -dy : dy;
    return dy / (1.0f + abs_dy);
}

/**
 * @brief 하이브리드 의수 시스템 구조 초기화 함수
 */
static inline void biocerve_hybrid_init(HybridFingerNode* const self, uint8_t id, int status, float weight) {
    self->finger_id = id;
    self->finger_status = status;
    self->synergy_weight = weight;
    self->current_pos = 0.0f;
    self->target_pos = 0.0f;
    self->feedback_current = 0.0f;
    self->live_flex_input = 0.0f;
    self->p00 = 1.0f;
    self->strike_count = 0;
    self->is_dead = false;
}

/**
 * @brief 하이브리드 실시간 전류 피드백 스캔 및 자율 세포 사멸(Apoptosis) 엔진
 */
static inline void biocerve_hybrid_feedback_scan(HybridFingerNode fingers[], float* raw_current_sensors) {
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        // [GUARD 1-1] 생체 존치 손가락은 물리적 모터가 없으므로 피드백 스캔 생략 및 보호
        if (fingers[i].finger_status == 0) {
            fingers[i].feedback_current = 0.0f;
            fingers[i].strike_count = 0;
            fingers[i].is_dead = false;
            continue;
        }

        // [GUARD 1-2] IEEE 754 표준 가드를 이용한 단선 및 전압 폭주(NaN) 즉시 포획
        if (raw_current_sensors[i] != raw_current_sensors[i]) {
            fingers[i].is_dead = true;
            fingers[i].feedback_current = -99.0f;
            continue;
        }

        if (fingers[i].is_dead) continue;
        fingers[i].feedback_current = raw_current_sensors[i];

        // 전류 임계치 연속 타격 모니터링 (Wedge-Lock 유도 가드)
        if (fingers[i].feedback_current >= CURRENT_CRITICAL_MA) {
            fingers[i].strike_count++;
            if (fingers[i].strike_count >= OVERLOAD_STRIKE_MAX) {
                fingers[i].is_dead = true; // 세포 사멸 집행
                fingers[i].target_pos = fingers[i].current_pos; // 현 위치 프리징 잠금
                continue;
            }
        } else {
            // [1차 자가 치유 사상 계승] 오진 방지용 점진적 카운터 감쇄
            if (fingers[i].strike_count > 0) fingers[i].strike_count--;
        }
    }
}

/**
 * @brief 생체 미러링 및 사선 대각선 우회장 통합 매핑 집행 커널
 * @param global_cmd 센서가 없는 비상 상황 시 전완부 근전도 등 전체 신호 입력값
 * @param out_pwms 최종 연산 완료된 12비트 타이머 주입용 PWM 결과 배열
 */
static inline void biocerve_hybrid_mapping_execute(HybridFingerNode fingers[], float global_cmd, int* out_pwms) {
    float alive_synergy_pool = 0.0f;
    float master_mirror_angle = 0.0f;
    bool  has_active_mirror = false;

    // ── STAGE 1: 생체 손가락(Status 0) 굽힘 센서에서 마스터 궤적(Master Angle) 검출 ──
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        if (fingers[i].finger_status == 0) {
            if (fingers[i].live_flex_input > master_mirror_angle) {
                master_mirror_angle = fingers[i].live_flex_input;
                has_active_mirror = true;
            }
        }
    }

    // ── STAGE 2: 생존한 기계 의수 마디의 동적 시너지 분모 풀 계산 ──
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        if (fingers[i].finger_status == 0) continue; // 생체 자리는 모터 연산 제외
        if (fingers[i].is_dead) continue;            // 사멸 노드 제외

        // 조셉 폼(Joseph Form) 공분산 필터 실드 전개 (반올림 오차 필터 폭주 방지)
        float K_gain = fingers[i].p00 / (fingers[i].p00 + 1.0f);
        fingers[i].p00 = ((1.0f - K_gain) * fingers[i].p00 * (1.0f - K_gain)) + (K_gain * 1.0f * K_gain);

        // 살아남은 의수 가중치 지분 합산
        alive_synergy_pool += fingers[i].synergy_weight;
    }

    // [GUARD 2] 만약 모든 기계 구동 마디가 전멸했다면 안전 셧다운 락업
    if (alive_synergy_pool <= 0.001f) {
        for (int i = 0; i < HYBRID_FINGERS; i++) {
            if (fingers[i].finger_status == 1) out_pwms[i] = MOTOR_PWM_MIN;
        }
        return;
    }

    // ── STAGE 3: 사선 대각선 우회장 및 미러링 궤적 최종 PWM 사산 매핑 ──
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        // 생체 손가락 자리는 구멍 관통 구조이므로 PWM 신호 인가를 차단하고 리턴
        if (fingers[i].finger_status == 0) {
            out_pwms[i] = MOTOR_PWM_MIN;
            continue;
        }

        // 전류 사멸 마디는 전원을 완전히 오프하여 하드웨어 Wedge-Lock 잠금 가동
        if (fingers[i].is_dead) {
            out_pwms[i] = MOTOR_PWM_MIN;
            continue;
        }

        // 우회장 수식: 사멸 노드의 지분을 배제하고 살아남은 마디로 동적 지분 반비례 분배
        float dynamic_allocation = fingers[i].synergy_weight / alive_synergy_pool;
        float mix_factor = 0.0f;

        if (has_active_mirror) {
            // 🎯 [생체 미러링 모드]: 0~90도 센서 입력을 파데 유리함수로 스mu딩 압축 후 매핑
            float error_gradient = master_mirror_angle - fingers[i].current_pos;
            float compressed_mirror = biocerve_hybrid_pade(error_gradient);
            
            // 현재 위치 추적용 변화율에 동적 분배 비 지분 가중 결합
            fingers[i].target_pos += compressed_mirror * dynamic_allocation * 4.5f;
            
            // 수치 마진 범위 제한 후 비선형 소용돌이 기하 속도 도출
            float norm_pos = fingers[i].target_pos / 90.0f;
            mix_factor = (norm_pos < 0.0f) ? 0.0f : (norm_pos > 1.0f) ? 1.0f : norm_pos;
        } else {
            // [글로벌 비상 명령 모드]: 전완부 총합 신호 구동
            float compressed_cmd = biocerve_hybrid_pade(global_cmd);
            float allocation_val = compressed_cmd * dynamic_allocation;
            mix_factor = (allocation_val < 0.0f) ? 0.0f : (allocation_val > 1.0f) ? 1.0f : allocation_val;
        }

        // 물리적 서보 모터 PWM 12비트 레인지 변환용 스케일링 마감 (비선형 소용돌이 가속 가중)
        float final_factor = mix_factor * mix_factor;
        out_pwms[i] = (int)(MOTOR_PWM_MIN + (MOTOR_PWM_MAX - MOTOR_PWM_MIN) * final_factor);
        
        // 실시간 현재 위치 캐싱 루프 (다음 틱 오차 추적용)
        fingers[i].current_pos = (out_pwms[i] - MOTOR_PWM_MIN) * 90.0f / (MOTOR_PWM_MAX - MOTOR_PWM_MIN);
    }
}

#endif // BIOCERVE_HYBRID_CORE_H
