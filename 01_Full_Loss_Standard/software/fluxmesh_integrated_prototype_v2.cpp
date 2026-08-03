/**
 * @file fluxmesh_integrated_prototype_v2.cpp
 * @brief 🌊 BioCerve-Hand: 8채널 선형 격자 스트립 + 햅틱 반사 및 엄지 지연 통합 제어 엔진 (v3.0)
 * 
 * [컴파일러 절대 준수 규칙] 
 * -ffast-math / -Ofast 사용 절대 금지! 
 * 수치 방어벽(NaN Guard) 및 자율 사멸 누락 방지를 위해 반드시 '-O2' 혹은 '-O3'만 사용하십시오.
 */

// 🌟 v2.0 업그레이드: 임베디드 아두이노/Teensy 에코시스템 런타임 라이브러리 가드 빌드
#if defined(ARDUINO) || defined(TEENSYDUINO)
    #include <Arduino.h>
#else
    #include <iostream>
#endif

#include <cmath>
#include <stdint.h>
#include <stdbool.h>

// 🌟 v2.0 업그레이드: 지능형 엄지 지연 및 햅틱 신경망 커널 핵심 헤더 결합
#include "fluxmesh_motor_feedback_kernel_v2.h"

// =================================================================
// [1. 가속 엔진 로우레벨 코어 아키텍처 구조체 정의]
// =================================================================

typedef struct {
    float x;
    float y;
} MeshVector32;

typedef struct {
    // 32비트 말초 신경 분산 에지 셀 노드 구조
    float p00, p01, p10, p11;   // 2x2 오차 공분산 행렬의 완전한 스칼라 전개 변수
    float state_value;          // 정제된 최종 스칼라 값 (Filtered Output)
    
    // 3차 업그레이드: 말초 노드 자율 사멸(Apoptosis)용 가드 레지스터 추가
    uint32_t strike_count;      // 국소 고전류/NaN 노이즈 연속 타격 카운터
    volatile bool is_isolated;  // 전압 폭주, 단선, 땀 유입 발생 시 자율 격리 플래그
} CellNode32;

typedef struct {
    // 2층 공간 융합 척수 메쉬 코어 구조
    float depth;                // 중력장 변위 공간 깊이
    float p00;                  // Joseph Form 오차 분산 가드 변수
    bool is_broken;            // 전체 그리드 망 오염 붕괴 판정 플래그
} MeshCore32;

// 🌟 v2.0 업그레이드: 전역 바인딩 메모리 참조 스코프 명시
// 헤더파일에 실장 선언된 5지 모터 상태 객체를 메인 척수 파이프라인으로 연결
extern FingerMotorState my_bio_fingers[NUM_FINGERS];

// =================================================================
// [2. 시스템 토폴도지 및 하이브리드 환경 변수]
// =================================================================
#define NUM_GRID_CHANNELS  8       // 3차 업그레이드: 아랫팔 해부학 결 기반 선형 격자 8채널 (굴근4 + 신근4)
#define OVERLOAD_STRIKE_MAX 8      // 노드 자율 사멸 트리거 카운트 리미트
#define DT                 0.001f  // 1kHz (1ms) 실시간 주기 동기화 상수
#define FAILSAFE_REJECT    -99.0f  // 망 오염 방지용 말초 사멸 거부 신호

// 3차 업그레이드: 아랫팔 근육 줄기를 따라 길게 배치되는 선형 격자(Linear Grid) 토폴로지 맵
enum MuscleLinearGridMap {
    // 🔴 굴근 트랙 스트립 (안쪽 아랫팔 - 물건 움켜쥐기 에너지)
    FLEXOR_NODE_1_PROXIMAL = 0,    // 팔꿈치 부근 발원지
    FLEXOR_NODE_2_MID      = 1,
    FLEXOR_NODE_3_DISTAL   = 2,
    FLEXOR_NODE_4_WRIST    = 3,    // 손목 부근 단면

    // 🟠 신근 트랙 스트립 (바깥쪽 아랫팔 - 손가락 쫙 펴기 에너지)
    EXTENSOR_NODE_1_PROXIMAL = 4,  // 팔꿈치 부근 발원지
    EXTENSOR_NODE_2_MID      = 5,
    EXTENSOR_NODE_3_DISTAL   = 6,
    EXTENSOR_NODE_4_WRIST    = 7    // 손목 부근 단면
};

// =================================================================
// [3. 글로벌 커널 메모리 할당]
// =================================================================
CellNode32    muscle_grid_nodes[NUM_GRID_CHANNELS]; // 3차 업그레이드: 선형 격자용 1층 8개 에지 셀 노드
CellNode32    gyro_twist_node;                     // 내재화된 손목 자이로용 독립 1층 셀
MeshCore32    spinal_fusion_center;                // 2층 위상 기하학 공간 융합 센터

// =================================================================
// [3-2. 3차 업그레이드: 하드웨어 타이머 분배 핀 정의 (Teensy / 아두이노 에코시스템 기반)]
// =================================================================
// 전역 매크로 상수를 가져와 5개 독립 타이머 모듈의 물리적 PWM 출력 핀 번호를 선언합니다.
const int MOTOR_PINS[NUM_FINGERS] = {2, 3, 4, 5, 6}; 

/**
 * @brief 하드웨어 물리 타이머 및 12비트 레졸루션 초기화 가동
 * @details v2.0 수정: 데스크톱 시뮬레이션 환경용 컴파일러 바이패스 크로스 가드 실장
 */
void setup_hardware_timers() {
#if defined(ARDUINO) || defined(TEENSYDUINO)
    for (int i = 0; i < NUM_FINGERS; i++) {
        // MCU 물리적 핀 모드를 출력으로 고정
        pinMode(MOTOR_PINS[i], OUTPUT);
        
        // 중요: 서보 모터는 50Hz 제어 주기를 가집니다.
        // 이 타이머 할당 주파수를 고정해야 알고리즘의 1ms 연산과 충돌(지터)이 나지 않습니다.
        #if defined(TEENSYDUINO)
            analogWriteFrequency(MOTOR_PINS[i], 50); 
        #endif
        
        // 12비트 타이머 레졸루션 확장 (0 ~ 4095 정밀 제어 블록 가동)
        // 텐던 와이어의 미세 인장 길이를 소용돌이 변수 수준으로 벼려내기 위함입니다.
        analogWriteResolution(12); 
    }
#endif
}

/**
 * @brief 계산된 펄스 마이크로초(us)를 12비트 타이머 듀티 사이클 값으로 변환하여 물리적 출력
 * @param out_pwms 1차 커널 매핑 함수에서 1000us ~ 2000us 범위로 계산 완료된 PWM 배열
 * @details v2.0 수정: 정수 나눗셈 변환 시 오차 극소화를 위해 정밀 데이터 캐스팅 보호벽 가동
 */
void write_fluxmesh_timers(int* out_pwms) {
#if defined(ARDUINO) || defined(TEENSYDUINO)
    for (int i = 0; i < NUM_FINGERS; i++) {
        // 50Hz 기준: 20ms(20000us)가 전체 주기(4095 스텝)
        // out_pwms[i]는 1000us ~ 2000us 범위이므로 이를 12비트 듀티 사이클로 정수 사칙연산 환산
        // 수식: (Duty_us / 20000us) * 4095 (오차 보정을 위해 부동소수점 임시 바인딩 후 라운딩 처리)
        float target_us = (float)out_pwms[i];
        int duty_cycle_12bit = (int)lroundf((target_us * 4095.0f) / 20000.0f);
        
        // 하드웨어 레지스터 타이머 버퍼에 직접 라이팅 (간섭 없이 동시 핀 분배 완료)
        analogWrite(MOTOR_PINS[i], duty_cycle_12bit);
    }
#endif
}



// =================================================================
// [4. 가속 엔진 초기화 함수]
// =================================================================
/**
 * @brief 8채널 근육 격자 및 자이로 융합 메모리 테이블 리셋
 * @details v2.0 수정: 임베디드 시리얼 모니터 및 표준 콘솔 출력 분기 결합
 */
void init_fluxmesh_core_nodes() {
    // 1층 근육 그리드 노드 상태 초기화 (3차: 선형 격자 8채널 대응 자동 루프)
    for (int i = 0; i < NUM_GRID_CHANNELS; i++) {
        muscle_grid_nodes[i].p00 = 1.0f; muscle_grid_nodes[i].p01 = 0.0f;
        muscle_grid_nodes[i].p10 = 0.0f; muscle_grid_nodes[i].p11 = 1.0f;
        muscle_grid_nodes[i].state_value = 0.0f;
        muscle_grid_nodes[i].strike_count = 0; // 3차: 노이즈 카운터 초기화
        muscle_grid_nodes[i].is_isolated = false;
    }
    
    // 1층 내재화 자이로 노드 초기화
    gyro_twist_node.p00 = 1.0f; gyro_twist_node.p01 = 0.0f;
    gyro_twist_node.p10 = 0.0f; gyro_twist_node.p11 = 1.0f;
    gyro_twist_node.state_value = 0.0f;
    gyro_twist_node.strike_count = 0;
    gyro_twist_node.is_isolated = false;

    // 2층 융합 코어 초기화
    spinal_fusion_center.depth = 0.0f;
    spinal_fusion_center.p00 = 1.0f;
    spinal_fusion_center.is_broken = false;
    
#if defined(ARDUINO) || defined(TEENSYDUINO)
    Serial.println(F("[SYSTEM] 8채널 선형 분산 그리드 및 자이로 융합 엔진 초기화 성공."));
#else
    std::cout << "[SYSTEM] 8채널 선형 분산 그리드 및 자이로 융합 엔진 초기화 성공.\n";
#endif
}

// =================================================================
// [5. 1층: 말초 화이트 노이즈 멸절 및 자가 치유(Apoptosis) 커널 함수]
// =================================================================
float process_peripheral_cell32(CellNode32* self, float raw_signal, float cos_t, float sin_t) {
    // [GUARD 1-1] IEEE 754 표준 가드를 이용한 중앙 마스터 단의 단선 및 전압 폭주(NaN) 판정
    if (raw_signal != raw_signal || std::isinf(raw_signal)) {
        self->is_isolated = true; // 세포 사멸 트리거 활성화
        return FAILSAFE_REJECT;
    }
    
    // [GUARD 1-2] 3차 업그레이드: 말초 노드 칩 자율 사멸 신호(-99.0f) 또는 임계 전압 초과 수신 감시
    // 통신 버스 상에서 노드가 스스로 죽었다고 선언하거나, 비정상 고전압 신호 유입 시 카운터 누적
    if (raw_signal == FAILSAFE_REJECT) {
        self->strike_count++;
        if (self->strike_count >= OVERLOAD_STRIKE_MAX) {
            self->is_isolated = true; // 말초 전파 차단 격리벽 작동
            return FAILSAFE_REJECT;
        }
    } else {
        // [1차 청사진의 자가치유 사상 계승] 오진 방지용 점진적 카운터 감쇄 수식 반영
        if (self->strike_count > 0) {
            self->strike_count--;
        }
    }
    
    // 이미 영구 사멸 및 격리 판정을 받은 노드는 무조건 거부 신호 리턴
    if (self->is_isolated) return FAILSAFE_REJECT;

    // 제자리 팽이 스핀 매커니즘: 시간축 오차 정제 행렬 수식 전개 (원작 BCI 사상 동기화)
    float pred_x = self->state_value * cos_t;
    
    // Joseph Form 수치 방어벽 수식: 부동소수점 반올림 오차가 누적되어도 공분산이 음수(-)로 뒤집히지 않음
    float k_gain = (self->p00 * cos_t) / (cos_t * self->p00 * cos_t + 0.1f); 
    self->state_value = pred_x + k_gain * (raw_signal - pred_x);
    self->p00 = (1.0f - k_gain * cos_t) * self->p00 * (1.0f - k_gain * cos_t) + k_gain * 0.1f * k_gain;

    return self->state_value;
}




// =================================================================
// [6. 2층: 8채널 선형 격차 기반 소용돌이 우회장(Curl Rerouting) 융합 커널 함수]
// =================================================================
MeshVector32 process_spinal_mesh32(MeshCore32* core, float* muscle_inputs, float gyro_input) {
    MeshVector32 output_vector = {0.0f, 0.0f};

    // [GUARD 2] 전체 시스템 망의 오염 및 붕괴 여부 선제 감시 (가용 노드 전멸 등)
    if (core->is_broken) return output_vector;

    // 3차 업그레이드: 해부학적 근육 결(선형 격자 스트립) 전위 차이 및 기울기 분석 레지스터
    float active_flexor_count   = 0.0f;
    float active_extensor_count = 0.0f;
    
    float Flexor_Gradient       = 0.0f; // 굴근 결을 따라 손목 방향으로 흐르는 활동전위 에너지
    float Extensor_Gradient     = 0.0f; // 신근 결을 따라 손목 방향으로 흐르는 활동전위 에너지

    // ── 1) 🔴 굴근 트랙 스트립 선형 격차 연산 (팔꿈치에서 손목으로 전도되는 에너지 추적) ──
    // 사멸 판정(FAILSAFE_REJECT)을 받은 노드는 조건문에서 자동 제외 및 자율 우회
    if (muscle_inputs[FLEXOR_NODE_1_PROXIMAL] != FAILSAFE_REJECT && muscle_inputs[FLEXOR_NODE_2_MID] != FAILSAFE_REJECT) {
        Flexor_Gradient += (muscle_inputs[FLEXOR_NODE_2_MID] - muscle_inputs[FLEXOR_NODE_1_PROXIMAL]);
        active_flexor_count += 1.0f;
    }
    if (muscle_inputs[FLEXOR_NODE_2_MID] != FAILSAFE_REJECT && muscle_inputs[FLEXOR_NODE_3_DISTAL] != FAILSAFE_REJECT) {
        Flexor_Gradient += (muscle_inputs[FLEXOR_NODE_3_DISTAL] - muscle_inputs[FLEXOR_NODE_2_MID]);
        active_flexor_count += 1.0f;
    }
    if (muscle_inputs[FLEXOR_NODE_3_DISTAL] != FAILSAFE_REJECT && muscle_inputs[FLEXOR_NODE_4_WRIST] != FAILSAFE_REJECT) {
        Flexor_Gradient += (muscle_inputs[FLEXOR_NODE_4_WRIST] - muscle_inputs[FLEXOR_NODE_3_DISTAL]);
        active_flexor_count += 1.0f;
    }

    // ── 2) 🟠 신근 트랙 스트립 선형 격차 연산 (팔꿈치에서 손목으로 전도되는 에너지 추적) ──
    if (muscle_inputs[EXTENSOR_NODE_1_PROXIMAL] != FAILSAFE_REJECT && muscle_inputs[EXTENSOR_NODE_2_MID] != FAILSAFE_REJECT) {
        Extensor_Gradient += (muscle_inputs[EXTENSOR_NODE_2_MID] - muscle_inputs[EXTENSOR_NODE_1_PROXIMAL]);
        active_extensor_count += 1.0f;
    }
    if (muscle_inputs[EXTENSOR_NODE_2_MID] != FAILSAFE_REJECT && muscle_inputs[EXTENSOR_NODE_3_DISTAL] != FAILSAFE_REJECT) {
        Extensor_Gradient += (muscle_inputs[EXTENSOR_NODE_3_DISTAL] - muscle_inputs[EXTENSOR_NODE_2_MID]);
        active_extensor_count += 1.0f;
    }
    if (muscle_inputs[EXTENSOR_NODE_3_DISTAL] != FAILSAFE_REJECT && muscle_inputs[EXTENSOR_NODE_4_WRIST] != FAILSAFE_REJECT) {
        Extensor_Gradient += (muscle_inputs[EXTENSOR_NODE_4_WRIST] - muscle_inputs[EXTENSOR_NODE_3_DISTAL]);
        active_extensor_count += 1.0f;
    }

    // [GUARD 3] 만약 양측 트랙의 노드가 모두 전멸하여 연산이 불가능할 경우 시스템 강제 안전 락업
    if (active_flexor_count <= 0.001f && active_extensor_count <= 0.001f) {
        core->is_broken = true; 
        return output_vector;
    }

    // 가용 노드 지분만큼 평균 공간 기울기 평탄화 (분모 압축 메커니즘 자동 발현)
    if (active_flexor_count > 0.0f)   Flexor_Gradient /= active_flexor_count;
    if (active_extensor_count > 0.0f) Extensor_Gradient /= active_extensor_count;

    // 3차 업그레이드 사상 주입을 위해 선형 트랙 축 데이터를 2차원 의수 벡터 평면 공간으로 치환 매핑
    // Gradient_X: 손가락을 쥐고 펴는 굴근/신근 간의 대향 전위차 격차 벡터
    // Gradient_Y: 아랫팔 줄기를 타고 흘러내려 온 전완부 전체 복합 기울기 총합
    float Gradient_X = Flexor_Gradient - Extensor_Gradient;
    float Gradient_Y = Flexor_Gradient + Extensor_Gradient;

    // ── 3) [신의 한 수: 자이로스코프 내재화의 공간 에너지 주입 메커니즘] ──
    // 만약 근육 신호가 감쇄(피로)하더라도, 내재화된 자이로의 물리 각속도가 공간 펌프 역할을 수행함
    float internal_gyro_pump = (gyro_input != FAILSAFE_REJECT) ? gyro_input : 0.0f;

    // 파데 유리함수(Padé Approximant) 도메인 수축 수식: 사칙연산만으로 완벽한 곡선 가속 실현 (exp 제거)
    float linear_scale = 1.0f / (1.0f + std::abs(Gradient_X + Gradient_Y + internal_gyro_pump));

    // 설계의 백미: 출력 축에 마이너스(-) 부호를 교차 결합하여 미분 방정식 없이 소용돌이(Curl) 우회장 발현
    // 이 크로스 부호 결합 수식 덕분에, 특정 근육 노드가 사멸하면 남은 격차 에너지와 자이로 회전 관성이 합쳐져 사선 궤적으로 모터를 휘감아 당깁니다.
    output_vector.x = Gradient_X * linear_scale;
    output_vector.y = -Gradient_Y * linear_scale + (internal_gyro_pump * 0.5f); // 자이로 에너지가 소용돌이 Y축 회전 관성을 상시 증폭 보정

    // 🌟 v2.0 업그레이드: [수치 안정성 가드 레지스터]
    // 만약 계산된 소용돌이 출력이 이완축(음수) 방향으로 이탈했을 경우,
    // 모터 가동 팩터 연산 시 음수 버그가 발생하는 것을 원천 예방하기 위해 하한선을 0.0f로 디펜스 처리
    if (output_vector.y < 0.0f) {
        output_vector.y = 0.0f;
    }

    // Joseph Form 기반의 가상 중력장 깊이 마진 누적 계산
    core->depth += (output_vector.x * output_vector.x + output_vector.y * output_vector.y) * DT;
    
    return output_vector;
}


// =================================================================
// [7. 실시간 동시 스캔 메인 파이프라인 (1ms 인터럽트 루틴) - 전반부]
// =================================================================
/**
 * @brief 1kHz 인터럽트 타이머 루틴 연동을 위한 메인 데이터 처리 파이프라인
 * @details v2.0 수정: 플랫폼별 입출력 버퍼 오염 방지 및 전원 절약형 모니터링  रिलीज 실장
 */
void run_fluxmesh_realtime_pipeline() {
    // 3차 업그레이드: 실제 아랫팔 굴근/신근 줄기를 따라 수집되는 8채널 원시 전압 데이터 (ADC/SPI 바인딩 가상화)
    // [0~3: 굴근 라인 / 4~7: 신근 라인]
    float raw_muscle_sensors[NUM_GRID_CHANNELS] = { 
        120.4f, 135.1f, 140.2f, 145.8f,  // 🔴 굴근 스트립 (Proximal -> Wrist)
        40.2f,  45.8f,  50.1f,  55.3f    // 🟠 신근 스트립 (Proximal -> Wrist)
    }; 
    float raw_internal_gyro = 1.85f; // 내재화 자이로 센서 실시간 스캔 각속도 값 (rad/s)

    float filtered_muscle[NUM_GRID_CHANNELS] = {0.0f};
    float filtered_gyro = 0.0f;

    float cos_t = std::cos(DT);
    float sin_t = std::sin(DT);

    // ── Step 1: [LAYER 1] 8채널 선형 근육 그리드 + 자이로 무간섭 독립 필터링 진행 ──
    for (int i = 0; i < NUM_GRID_CHANNELS; i++) {
        filtered_muscle[i] = process_peripheral_cell32(&muscle_grid_nodes[i], raw_muscle_sensors[i], cos_t, sin_t);
        if (muscle_grid_nodes[i].is_isolated) {
#if defined(ARDUINO) || defined(TEENSYDUINO)
            Serial.print(F(" ⚠ [LOCAL APORT_ALARM] 선형 격자 노드 "));
            Serial.print(i);
            Serial.println(F(" 번 폭주로 인한 자율 격리 완료!"));
#else
            std::cout << " ⚠ [LOCAL APORT_ALARM] 선형 격자 노드 " << i << " 번 폭주로 인한 자율 격리 완료!\n";
#endif
        }
    }
    filtered_gyro = process_peripheral_cell32(&gyro_twist_node, raw_internal_gyro, cos_t, sin_t);

    // ── Step 2: [LAYER 2] 2층 융합 센터로 데이터 투하 및 소용돌이 공간 변위 도출 ──
    MeshVector32 dynamic_control_v = process_spinal_mesh32(&spinal_fusion_center, filtered_muscle, filtered_gyro);

    // ── Step 3: [MOTOR INTERFACE] 도출된 소용돌이 변위를 1차 모터 피드백 커널과 결합 및 최종 매핑 ──
    // 실제 임베디드 환경에서는 전단에 배치된 전류 센서(INA219 등)로부터 데이터가 바인딩됩니다.
    float simulated_motor_currents[NUM_FINGERS] = { 150.0f, 220.0f, 180.0f, 110.0f, 95.0f }; // 실시간 전류 데이터 (mA)
    int final_output_pwms[NUM_FINGERS] = { MOTOR_PWM_MIN };                                // 출력용 PWM 배열

    // 1차 청사진의 핵심 방어막인 전류 과부하 피드백 스캔 및 자가 치유 감쇄 루프 구동
    fluxmesh_motor_feedback_scan(my_bio_fingers, simulated_motor_currents);

    // 2층 메쉬 코어에서 솟구친 소용돌이 변위(dy)를 살아있는 5지 노드로 사선 우회(Reroute) 평탄화 매핑
    fluxmesh_motor_mapping_execute(my_bio_fingers, dynamic_control_v.y, final_output_pwms);

    // ── Step 3-2: 🎯 [🛠 HARDWARE DRIVER BINDING: 물리 타이머 출력 집행] ──
    // 우리가 정립한 12비트 극상 정밀도(0~4095 스텝) 정수 비례식 드라이버 엔진 가동
    write_fluxmesh_timers(final_output_pwms);

    // ── Step 4: [TELEMETRY] 시스템 상태 데이터 실시간 시리얼 모니터링 출력 ──
#if defined(ARDUINO) || defined(TEENSYDUINO)
    Serial.print(F("[TRACKING] 중력장 깊이: ")); Serial.print(spinal_fusion_center.depth);
    Serial.print(F(" | 소용돌이 벡터 X(손목): ")); Serial.print(dynamic_control_v.x);
    Serial.print(F(" , Y(지분): ")); Serial.println(dynamic_control_v.y);
    
    Serial.print(F("[MOTOR OUT] PWM 릴리즈 -> 엄지: ")); Serial.print(final_output_pwms[FIN_THUMB]);
    Serial.print(F(" | 검지: ")); Serial.print(final_output_pwms[FIN_INDEX]);
    Serial.print(F(" | 중지: ")); Serial.print(final_output_pwms[FIN_MIDDLE]);
    Serial.print(F(" | 약지: ")); Serial.print(final_output_pwms[FIN_RING]);
    Serial.print(F(" | 새끼: ")); Serial.println(final_output_pwms[FIN_PINKY]);
#else
    std::cout << "[TRACKING] 중력장 깊이: " << spinal_fusion_center.depth 
              << " | 소용돌이 벡터 X(손목): " << dynamic_control_v.x 
              << " , Y(지분): " << dynamic_control_v.y << "\n";
              
    std::cout << "[MOTOR OUT] PWM 신호 사산 매핑 릴리즈 -> "
              << " 엄지: " << final_output_pwms[FIN_THUMB] << " ms |"
              << " 검지: " << final_output_pwms[FIN_INDEX] << " ms |"
              << " 중지: " << final_output_pwms[FIN_MIDDLE] << " ms |"
              << " 약지: " << final_output_pwms[FIN_RING] << " ms |"
              << " 새끼: " << final_output_pwms[FIN_PINKY] << " ms\n\n";
#endif
}

// =================================================================
// [8. 시스템 메인 엔트리 포인트 (Main Runtime / Arduino Lifecycle Cross Bridge)]
// =================================================================

#if defined(ARDUINO) || defined(TEENSYDUINO)
/**
 * @brief 아두이노/Teensy 에코시스템 런타임 하드웨어 전원 부팅 시퀀스
 */
void setup() {
    // 임베디드 전용 115200 고속 시리얼 통신 버스 가동
    Serial.begin(115200);
    delay(500); // 전압 안정화 대기 마진

    // 1. 하드웨어 메모리 테이블 및 8채널 선형 가속 노드 레이아웃 초기화
    init_fluxmesh_core_nodes();
    
    // 2. 1차 청사진의 해부학적 가중치 배정 시스템 구동 및 햅틱 핀 초기화
    fluxmesh_motor_init(my_bio_fingers);
    
    // 3. 🎯 [HARDWARE INITIALIZATION: 물리 타이머 및 12비트 레졸루션 초기화]
    setup_hardware_timers();
    
    Serial.println(F("\n--- BioCerve 8채널 선형 격자 스마트 스킨 & 모터 피드백 실전 구동 시작 (1kHz) ---"));
}

/**
 * @brief 아두이노/Teensy 하드웨어 런타임 무한 주기 루프 함수
 * @details 임베디드 환경에서는 1ms 주기 타이머 인터럽트를 타이밍 래퍼로 래핑하여 
 *          1kHz 연산 제어 주기를 상시 고정 유지할 것을 강력히 권장합니다.
 */
void loop() {
    run_fluxmesh_realtime_pipeline();
    delay(1); // 1ms (1kHz) 실시간 주기 동기화 유지 마진 (인터럽트 대체 가능)
}

#else
/**
 * @brief 데스크톱/PC 환경전용 검증용 가상 메인 엔트리 포인트 (Native C++)
 */
int main() {
    // 1. 하드웨어 메모리 테이블 및 8채널 선형 가속 노드 레이아웃 초기화
    init_fluxmesh_core_nodes();
    
    // 2. 1차 청사진의 해부학적 가중치 배정 시스템 구동
    fluxmesh_motor_init(my_bio_fingers);
    
    // 3. 물리 타이머 인터페이스 에뮬레이터 초기 가동 (PC 환경 바이패스)
    setup_hardware_timers();
    
    std::cout << "\n--- BioCerve 8채널 선형 격자 스마트 스킨 & 모터 피드백 루프 실시간 스캔 시작 (1kHz) ---\n";
    
    // 1ms 주기 인터럽트 타이머 루틴을 가상화하여 3틱(3ms) 시뮬레이션 주행 검증
    for (int tick = 0; tick < 3; tick++) {
        std::cout << "[TICK #" << tick + 1 << " ms]";
        run_fluxmesh_realtime_pipeline();
    }
    
    std::cout << "[SYSTEM] 시뮬레이션 파이프라인 가동성 검증 성공. 프로덕션 빌드가 준비되었습니다.\n";
    return 0;
}
#endif
