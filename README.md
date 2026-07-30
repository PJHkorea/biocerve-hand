# 🦾 biocerve-hand : FluxMesh Hardware & Signal Integration

**biocerve-hand**는 단일 대근육 표면에 고밀도 2x2 격자(Grid) 센서를 부착하여 활동전위(Action Potential)의 공간적 흐름을 포착하고, 이를 **미분 없는 기하학적 미분 공간 연산**을 통해 가상의 소용돌이(Curl) 벡터로 변환하는 **인공 신경 바이패스(Neural Bypass) 의수 플랫폼**입니다.

무거운 패턴 인식 AI(머신러닝) 학습 과정 없이, 임베디드 단의 로우레벨 연산(1kHz 루틴)만으로 5개 손가락의 독립적인 미세 분리 구동을 실시간 자율 유도합니다.

---

## 📌 주요 특징 (Key Features)

| 구분 | 01_Full_Loss_Standard (트랙 1) | 02_Hybrid_Partial_Loss (트랙 2) |
| :--- | :--- | :--- |
| **대상 환자** | 손목 이상 또는 손바닥 전체 소실 환자 | 특정 손가락 일부 소실 환자 |
| **구동 방식** | 5지(엄지~새끼) 완전 전동 구동 | 생체 손가락 + 전동 의수 하이브리드 |
| **핵심 커널** | **FluxMesh 2층 위상 공간 융합 엔진** | 굽힘 센서 기반 생체 미러링 |
| **신호 처리** | 2x2 HD-EMG 격차 + 자이로 통합 센서 융합 | 단일 손가락 관절 추적 동기화 |

---

## 📐 신호 결합 메커니즘 (Vector Flow Approach)

인간이 손가락을 움직일 때 발생하는 단일 근육 내부의 미세 전류 번짐 현상을 가상의 **'액체 전도막'** 기울기로 해석합니다.

```text
       [ 단일 근육 내 미세 신호 번짐 (활동전위 전파) ]
                            ⚡
                          /    \
                         ▼      ▼
                 [NORTH_WEST]  [NORTH_EAST]  <── 2x2 고밀도 격자 센서 패드
                 [SOUTH_WEST]  [SOUTH_EAST]
                       │        │
                       └─(FluxMesh Layer 2)──> Spatial Gradient (X, Y) 계산
                                │
                                ▼
               [ 설계의 백미 : 마이너스 교차 결합 ]
               output_vector.dy = -Spatial_Gradient_Y
                                │
                                ▼
         [ 소용돌이 우회장(Curl Rerouting) 변위 발생 ]
    🔄 전위가 소용돌이치는 방향과 회전력에 따라 5개 손가락 독립 분리 제어
```

---

## ⚡ 코어 아키텍처 및 하드웨어 방어벽 (Failsafe Kernel)

본 프로젝트의 핵심 가속 커널(`fluxmesh_integrated_prototype.cpp`)은 가혹한 생체 신호 환경 및 임베디드 단의 물리적 한계를 극복하기 위해 설계되었습니다.

### 1. 말초 세포 자가 치유 (Apoptosis / Local Isolation)
* **IEEE 754 가드**: 환자의 땀으로 인해 특정 격자 패드가 쇼트나거나, 단선되어 `NaN`(Not a Number) 혹은 `Inf`(무한대) 전압 폭주가 발생하면 시스템이 이를 즉시 감지합니다.
* **하드웨어 자동 격리**: 오염된 노드만 즉시 사멸(`is_isolated = true`) 처리하고 연산 망에서 영구 제외하여, 전체 시스템의 셧다운을 방기하고 가용 노드로만 우회 연산을 집행합니다.

### 2. Joseph Form 수치 방어벽 (Numerical Guard)
* 임베디드 환경에서 시간축 오차 정제 행렬 계산 시 반올림 오차가 무한히 누적되더라도, 오차 분산 값이 **절대로 음수(-)로 뒤집히지 않도록** 수학적 안전장치를 전개하여 커널 신뢰성을 극대화했습니다.

### 3. 내재화 자이로 융합 공간 펌프 (Internal Gyro Pump)
* 환자의 근육이 피로해져 EMG 신호의 진폭이 급격히 감쇄하더라도, 손목 관절에 내재화된 자이로스코프의 물리적 각속도 데이터가 **공간 에너지 펌프** 역할을 수행합니다. 
* 근육 격차 에너지와 자이로 회전 관성이 실시간 결합되어 소용돌이 Y축 회전 관성을 상시 증폭 보정합니다.

### 4. 파데 유리함수(Padé Approximant) 도메인 수축
* 자원이 제한된 MCU 환경을 고려하여, 연산 소모가 큰 지수함수(`exp`)를 전면 배제하고 오직 사칙연산만으로 완벽한 곡선 가속 스케일링(`1.0f / (1.0f + abs(Gradient))`)을 구현했습니다.

---

## 📂 프로젝트 구조 (Repository Structure)

```text
biocerve-hand/
├── LICENSE                    # GPLv3 / CERN-OHL-W v2 라이선스 전문
├── README.md                  # 프로젝트 전체 소개 및 퀵스타트 가이드
│
├── 01_Full_Loss_Standard/     # [트랙 1] 손 전체 소실 환자용 (기본 전동 의수)
│   ├── hardware/
│   │   └── biocerve_full.scad # 엄지~새끼 5지 완전 의수 도면 (.scad)
│   └── software/
│       ├── biocerve_core.h    # 근전도(EMG)/압력(FSR) 기반 전체 제어 소스 코드
│       └── fluxmesh_integrated_prototype.cpp # ★2x2 근육 그리드+자이로 융합 커널
│
└── 02_Hybrid_Partial_Loss/    # [트랙 2] 손가락 일부 소실 환자용 (하이브리드)
    ├── hardware/
    │   └── biocerve_hybrid.scad # finger_status 변수 분기 및 생체 손가락 관통 홀 도면
    └── software/
        └── biocerve_hybrid_core.h # 굽힘 센서 기반 생체 미러링 소스 코드
```

---

## 🛠️ 하드웨어 구축 가이드 (Hardware Configuration)

노이즈를 극도로 억제하고 고정밀 공간 기울기(Spatial Gradient)를 추출하기 위한 물리 하드웨어 구성 필수 지침입니다.

* **일체형 그리드 패드 사용 권장**: 센서 4개를 일반 전선으로 일일이 따로 부착하면 유도 노이즈가 폭발합니다. 유연한 FPCB(연성회로기판)나 전도성 하이드로겔을 이용해 2x2 바둑판 격자가 아예 한 장으로 인쇄된 일체형 패드를 제작하여 무간섭 신호를 수집하십시오.
* **공통 기준 전극(Reference GND) 심기**: 격자 센서들이 서로 간섭을 일으키지 않고 순수한 내부 전위 차이만 뽑아낼 수 있도록, 근육 신호가 전달되지 않는 **팔꿈치 유골 부위**나 **손목 뼈 근처**에 강력한 공통 GND를 확실하게 밀착시켜야 합니다.

---

## 💻 컴파일러 절대 준수 규칙 (Compiler Flag Warning)

```bash
# ⚠️ 주의: -ffast-math 또는 -Ofast 옵션 사용을 절대 금지합니다!
# 연산 가속을 위해 수치 가드를 해제하는 옵션을 사용하면 IEEE 754 NaN 가드가 무력화됩니다.
# 반드시 정밀 수치 방어가 유지되는 '-O2' 또는 '-O3' 최적화 플래그만 사용하여 컴파일하십시오.
```

---

## 📜 라이선스 (License)

본 프로젝트는 오픈소스 하드웨어 및 혁신적인 바이오 신호 알고리즘 생태계를 지지합니다.
* **Software**: GPLv3
* **Hardware**: CERN-OHL-W v2 (Weak Reciprocal 설계도면 공개 의무 적용)
