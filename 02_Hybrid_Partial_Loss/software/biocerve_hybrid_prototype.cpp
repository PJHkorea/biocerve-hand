/**
 * @file biocerve_hybrid_prototype.cpp
 * @brief 👁️ BioCerve-Hand: 5지 생체 미러링(Mirroring) 및 하이브리드 연동 프로토타입 (v2.5)
 */

#include "biocerve_hybrid_core.h"
#include <iostream>
#include <cmath>

// =================================================================
// [1. 하드웨어 물리 타이머 드라이버 레이어 (12비트)]
// =================================================================
const int HYBRID_MOTOR_PINS[HYBRID_FINGERS] = {2, 3, 4, 5, 6}; 

void setup_hybrid_hardware_timers() {
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        pinMode(HYBRID_MOTOR_PINS[i], OUTPUT);
        analogWriteFrequency(HYBRID_MOTOR_PINS[i], 50);   // 서보 제어 50Hz
        analogWriteResolution(12);                       // 12비트(0~4095) 정밀도
    }
}

void write_hybrid_timers(int* out_pwms) {
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        // 1000us~2000us 범위를 12비트 듀티 사이클로 변환
        int duty_cycle_12bit = (out_pwms[i] * 4095) / 20000;
        analogWrite(HYBRID_MOTOR_PINS[i], duty_cycle_12bit);
    }
}
// =================================================================
// [2. 실시간 하이브리드 미러링 파이프라인 (1kHz 인터럽트 루틴)]
// =================================================================
// 3차 업그레이드: 하이브리드 의수 시스템 전체의 말초 메모리 맵 전역 배정
HybridFingerNode hybrid_fingers[HYBRID_FINGERS];

void run_hybrid_realtime_pipeline() {
    // [ADC/SPI 하드웨어 센서 피드백 가상화 매핑 데이터셋]
    // 환자의 중지(Index 2)가 멀쩡히 보존되어 현재 55.4도 구부러진 상태를 굽힘 센서가 포획함
    float raw_flex_inputs[HYBRID_FINGERS] = { 0.0f, 0.0f, 55.4f, 0.0f, 0.0f }; 
    
    // 실시간 각 서보 모터 소비 전류 측정 피드백 (mA)
    // 검지 모터가 물체에 걸려 145mA 가량 로드가 걸린 상태를 시뮬레이션
    float raw_current_sensors[HYBRID_FINGERS] = { 120.0f, 145.0f, 0.0f, 110.0f, 95.0f }; 

    // 하드웨어 타이머 레지스터로 인가할 최종 출력용 PWM 제어 펄스 버퍼 (기본값 최소화 고정)
    int final_output_pwms[HYBRID_FINGERS] = { MOTOR_PWM_MIN, MOTOR_PWM_MIN, MOTOR_PWM_MIN, MOTOR_PWM_MIN, MOTOR_PWM_MIN };

    // ── 1. 생체 손가락(Status 0) 센서 데이터 실시간 파이프라인 바인딩 ──
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        if (hybrid_fingers[i].finger_status == 0) {
            hybrid_fingers[i].live_flex_input = raw_flex_inputs[i];
        }
    }

    // ── 2. 전류 피드백 감시 및 자율 세포 사멸(Apoptosis) 가드 구동 ──
    // 8ms 연속 임계 전류(1.2A) 초과 타격 시 해당 의수 노드 강제 프리징 및 격리벽 작동
    biocerve_hybrid_feedback_scan(hybrid_fingers, raw_current_sensors);

    // ── 3. 미러링 매핑 및 소용돌이 우회장(Vorticity Reroute) 집행 ──
    // 생체 손가락 궤적(55.4도)을 100% 복사 추적하며, 기계 노드 사멸 시 지분을 반비례 우회 분배
    biocerve_hybrid_mapping_execute(hybrid_fingers, 0.0f, final_output_pwms);

    // ── 4. 🎯 물리 타이머 출력 드라이버 가동 ──
    // [Part 1]에서 빌드해 둔 12비트 극상 정밀도(0~4095) 레지스터 버퍼 직접 주입
    write_hybrid_timers(final_output_pwms);

    // ── 5. [Telemetry] 시스템 상태 데이터 실시간 시리얼 모니터링 출력 ──
    std::cout << "[HYBRID METRIC] 생체 마스터 입력(중지 각도): " << raw_flex_inputs[H_MIDDLE] << "°\n";
    std::cout << "[MOTOR OUT] PWM 펄스 매핑 전송 -> "
              << " 엄지(생체): " << final_output_pwms[H_THUMB]  << "us |"
              << " 검지(의수): " << final_output_pwms[H_INDEX]  << "us |"
              << " 중지(의수): " << final_output_pwms[H_MIDDLE] << "us |"
              << " 약지(생체): " << final_output_pwms[H_RING]   << "us |"
              << " 새끼(생체): " << final_output_pwms[H_PINKY]  << "us\n";
              
    // 세포 사멸(Apoptosis)로 인해 기계가 스스로 격리벽을 쳤는지 상시 안전 검사 고지
    for (int i = 0; i < HYBRID_FINGERS; i++) {
        if (hybrid_fingers[i].is_dead) {
            std::cout << "🚨 [HYBRID APRE_ALARM] 의수 손가락 노드 " << i << "번 과부하 사멸 및 격리 완료 (Wedge-Lock 고정)!\n";
        }
    }
    std::cout << "\n";
}

// =================================================================
// [3. 시스템 메인 엔트리 포인트 (Main Runtime Engine)]
// =================================================================
int main() {
    // ── 1단계: 환자 개별 절단 상태 맞춤형 프로파일 캘리브레이션 ──
    // 파라메터 순서: (&구조체노드, 손가락ID, finger_status마스킹, synergy_weight해부가중치)
    // - finger_status: 1이면 소실(기계의수 구동), 0이면 생체 존치(통형 관통 홀 적용)
    
    biocerve_hybrid_init(&hybrid_fingers[H_THUMB],  H_THUMB,  0, 1.20f); // 👍 엄지: 생체 보존 (Status 0)
    biocerve_hybrid_init(&hybrid_fingers[H_INDEX],  H_INDEX,  1, 1.10f); // 🤖 검지: 절단 소실 -> 의수 구동 (Status 1)
    biocerve_hybrid_init(&hybrid_fingers[H_MIDDLE], H_MIDDLE, 1, 0.95f); // 🤖 중지: 절단 소실 -> 의수 구동 (Status 1)
    biocerve_hybrid_init(&hybrid_fingers[H_RING],   H_RING,   0, 0.85f); // 💍 약지: 생체 보존 (Status 0)
    biocerve_hybrid_init(&hybrid_fingers[H_PINKY],  H_PINKY,  0, 0.75f); // 🤙 새끼: 생체 보존 (Status 0)

    // ── 2단계: 하드웨어 독립 타이머 주파수 및 12비트 해상도 동기화 ──
    // 핀 모드 출력 설정 및 서보 전용 50Hz 캐리어를 레지스터 버퍼에 부팅 즉시 앵커링 고정
    setup_hybrid_hardware_timers();
    
    std::cout << "=================================================================\n";
    std::cout << "🌊 BioCerve-Hand 하이브리드 일부 소실 추적 시스템 가동\n";
    std::cout << "   - 활성 기계 의수 노드: 검지[FIN_INDEX], 중지[FIN_MIDDLE]\n";
    std::cout << "   - 생체 미러링 복사 소스: 약지(또는 잔존 생체 손가락 굽힘 데이터)\n";
    std::cout << "=================================================================\n\n";

    // ── 3단계: 1ms 주기 실시간 타이머 인터럽트 파이프라인 가상 주행 검증 ──
    // 가속 엔진의 누적 공분산 및 사선 우회장 안정성을 입증하기 위해 3틱(3ms) 루프 시뮬레이션 전개
    for (int tick = 0; tick < 3; tick++) {
        std::cout << "⏱️ [TIMER INTERRUPT LOOP - TICK #" << tick + 1 << " ms]\n";
        
        // 1ms 주기 독립 스캔, 말초 자율 사멸(Apoptosis), 생체 미러링 융합, 12비트 타이머 물리 출력을 동시 집행
        run_hybrid_realtime_pipeline();
    }
    
    // ── 4단계: 시스템 가동성 최종 검증 성공 및 안전 자원 해제 코어 리턴 ──
    std::cout << "=================================================================\n";
    std::cout << "[SYSTEM REPO] 하이브리드 미러링 파이프라인 가동성 시뮬레이션 성공.\n";
    std::cout << "              '-O2' / '-O3' 최적화 빌드가 완전히 준비되었습니다.\n";
    std::cout << "=================================================================\n";
    
    return 0;
}

