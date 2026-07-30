# 🧬 fluxmesh-hdw (FluxMesh Hardware & Signal Integration)

**fluxmesh-hdw**는 단일 대근육 표면에 고밀도 격자(Grid) 센서를 부착하여, 활동전위(Action Potential)의 공간적 전위 차이 흐름을 포착하고 이를 가상의 소용돌이(Curl) 벡터로 변환하는 **인공 신경 바이패스(Neural Bypass) 기반 생체 신호 처리 프레임워크**입니다.

무거운 패턴 인식 AI(머신러닝) 학습 과정 없이, 알고리즘 내부의 기하학적 미분 연산만으로 5개 손가락의 독립적인 미세 구동을 자율 유도합니다.

---

## 💡 기존 의수의 한계와 FluxMesh의 혁신 (Paradigm Shift)

### ❌ 기존 의수 신호 수집의 한계
* **징검다리식 배치**: 개별 센서를 듬성듬성 부착하여 신호가 번지는 크기(진폭)만 측정.
* **정보의 손실**: 단일 근육 내에서 신호가 어느 방향으로 이동하는지 추적 불가능.
* **복잡한 후처리**: 손가락을 분리 제어하기 위해 대규모 데이터 셋과 복잡한 ML/DL 학습 모델이 필수적임.

###  FluxMesh 그리드 솔루션 (Vector Flow Approach)
* **공간적 전위 차이 포착**: 단일 근육 내에서 전위가 전파(Propagation)되는 방향과 속도를 벡터 흐름으로 인식.
* **미분 없는 미분 공간 연산**: `neighbor_vectors` 구조를 통해 동서남북 인접 센서 간의 격차(기울기)를 실시간 계산.
* **소용돌이(Curl) 트릭**: 근육 내 미세 영역의 쏠림 현상을 가상의 회전 변위로 전환하여 손가락 분리 구동을 자연스럽게 유도.

---

## 📐 신호 결합 메커니즘 (Signal Coupling Mechanism)

근육 표면을 하나의 가상 **'액체 전도막'**으로 정의하고, 격자 센서에서 수집된 신호를 수학적 공간 변위로 매핑합니다.

```text
       [ 근육 내부의 미세 신호 번짐 (활동전위 전파) ]
                            ⚡
                          /    \
                         ▼      ▼
                      [북]      [동]  <── 고밀도 격자 센서 패드 (HD-EMG)
                       │        │
                       └─(FluxMesh Layer 2)──> Spatial Gradient 계산
                                │
                                ▼
               [ 마이너스 교차 결합 알고리즘 작동 ]
               output_vector.dy = -Spatial_Gradient_Y
                                │
                                ▼
                [ 소용돌이(Curl) 회전 변위 발생 ]
        🔄 방향과 회전력에 따라 5개 손가락 모터 독립 제어
```

---

## 🛠️ 하드웨어 아키텍처 및 구성 팁 (Hardware Configuration)

노이즈를 억제하고 고정밀 격자 신호(Spatial Gradient)를 추출하기 위한 임베디드 단의 하드웨어 구성 가이드라인입니다.

### 1. 일체형 그리드 어레이 패드 (Grid Array Pad)
* **문제점**: 개별 센서를 전선으로 따로 연결할 경우, 선 꼬임과 전자기적 노이즈(EMI)가 극대화됩니다.
* **솔루션**: 유연한 **FPCB(연성회로기판)** 또는 **전도성 하이드로겔**을 활용하여 `2x2` 또는 `4x1` 형태의 바둑판 격자가 한 장의 패드로 인쇄된 일체형 구조를 사용합니다.

### 2. 공통 기준 전극 (Reference GND) 배치
* **핵심 원리**: 격자 센서 간 상호 간섭을 차단하고 순수한 내부 전위 차이만 추출해야 합니다.
* **부착 위치**: 신호의 간섭이 없는 **팔꿈치 유골 부위** 또는 **손목 뼈 근처**에 강력한 공통 기준 전극(GND)을 확실히 고정합니다.

---

## 🗂️ 디렉토리 구조 (Directory Structure)

```text
fluxmesh-hdw/
├── hardware/
│   ├── fpcb/                  # 2x2 및 4x1 FPCB 그리드 어레이 거버(Gerber) 파일
│   └── schematics/            # 공통 기준 전극(GND) 및 아날로그 프론트엔드(AFE) 회로도
│
└── software/
    ├── include/
    │   └── fluxmesh_core.h    # neighbor_vectors 및 Spatial Gradient 연산 핵심 헤더
    └── src/
        └── fluxmesh_curl.c    # 마이너스 교차 결합 기반 소용돌이 벡터 연산 구현부
```

---

## 🚀 퀵 스타트 (Quick Start)

### 1. 하드웨어 준비
1. `hardware/fpcb/` 디렉토리의 거버 파일을 이용해 유연한 격자 패드를 제작합니다.
2. 대상 대근육(예: 전완근) 표면에 패드를 밀착시키고, Reference GND를 손목 뼈 부근에 부착합니다.

### 2. 소프트웨어 파라미터 설정
`fluxmesh_core.h` 파일에서 격자 배열의 물리적 간격 수치를 동기화합니다.

```c
// 예시: 격자 간격 및 이웃 벡터 노드 정의
#define GRID_SPACING_MM 10.0
#define NODE_COUNT      4

typedef struct {
    float node_val[NODE_COUNT];
    float spatial_gradient_x;
    float spatial_gradient_y;
} FluxMesh_Layer2;
```

---

## 📜 라이선스 (License)

본 프로젝트는 오픈소스 하드웨어 및 혁신적인 바이오 신호 알고리즘 생태계를 지지합니다.
* **Software**: MIT License
* **Hardware**: CERN OHL v2
