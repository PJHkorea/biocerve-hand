# 🦾 BioCerve-Hand: Parametric Prosthetic System & Signal Integration (v2.5)

**BioCerve-Hand**는 인체 구조를 모방한 **오픈소스 파라메트릭 의수 플랫폼 및 사이버네틱스 통제 커널**입니다. 기하학적 공간 곡률 설계와 수학적 분산 에지 컴퓨팅을 활용하여 5개 손가락의 유기적 분리 독립 구동을 실시간 자율 유도합니다.

---

## 🔬 핵심 하드웨어 관절 메커니즘 (Cybernetic Joint Architecture)

본 프로젝트는 무거운 기어박스를 배제하고 기하학적 형상 사출만으로 복합 관절 기능을 구현하는 특수 소켓 구조를 가집니다.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d7b38e13-34da-4447-a0b6-ebbb3df291e8" width="650" alt="BioCerve-Hand Joint Lock-in Architecture">
  <br>
  <em>주요 핵심 메커니즘: 1체형 구슬 락-인 및 최적화된 C-커브 텐던 경로 단면도</em>
</p>

- **중심 피벗 구슬 (Central Pivot Sphere)**: 인체의 볼-소켓 관절을 모사하여 전단 하중을 분산하고 부러짐을 원천 방어하는 목 보강 구조 일체형 주조.
- **수동 기계적 락-인 (Passive Mechanical Lock-In)**: 손가락이 뒤로 꺾이는 과신전을 물리적 차단 턱(Wedge-Lock)으로 잠가 버리는 기믹. 물건을 쥐고 버틸 때 모터 전류를 끊어도 물리 구조가 하중을 지탱하여 배터리 소모를 제로(0)화합니다.
- **최적화된 토크를 위한 C-커브 텐던 경로 (C-Curve Tendon Path)**: 관절이 구부러질 때 악력이 급격히 떨어지는 기존 3D 프린팅 의수의 약점을 보완하여, 전 구간 선형적 토크 모멘트 암을 확보하고 다이니마(Dyneema) 텐던 와이어의 쓸림과 보풀 파단을 방지하는 나팔꽃 모양 모따기(Chamfer Cone) 가드 내장.

---

## 📌 주요 아키텍처 트랙 선택 가이드 (Framework Tracks)

| 구분 | 🔴 트랙 1: Full Loss Standard (손 전체 소실) | 🔵 트랙 2: Hybrid Partial Loss (일부 소실) |
| :--- | :--- | :--- |
| **대상** | 손목 이상 소실 환자 | 특정 손가락 일부 소실 환자 (부분 절단) |
| **구동** | 5지(엄지~새끼) 완전 전동 기계 구동 | 생체 손가락 + 전동 의수 하이브리드 협응 |
| **센서** | 아랫팔 전완근 **8채널 선형 격자 스트립** | 잔존 생체 손가락 마디 위 **굽힘 센서(Flex)** |
| **커널** | 2층 척수 메쉬 소용돌이 변위 엔진 (Vorticity) | 직관적 생체 궤적 복사 미러링(Mirroring) 알고리즘 |
| **하드웨어** | 5지 완전체 파라메트릭 도면 (`.scad`) | **15도 앞쪽 사선형 생체 관통 홀** 매립 도면 |

---

## 🗺️ 데이터 파이프라인 아키텍처 (System Topology)

아랫팔 근육의 활동전위를 선형 격자 스트립으로 스캔하여 위상 기하학 평면 벡터로 매핑합니다.
- **동적 분모 압축 수식**: 특정 노드 사멸(`-99.0f`) 시 가용 노드 카운트만큼 자동 압축 배분되어 구동 연속성 유지.

```text
[데이터 파이프라인 파트]
├── 1. 하드웨어 입력단 (Sensor Layer)
│   └── (굴근/신근 트랙): 8채널 노드 (실시간 생체 굽힘 센서 데이터 수집)
│
├── 2. 통신 인프라단 (Bus Layer)
│   └── [단 3선 직렬 통신 Bus] (1ms 인터럽트 주기 고속 데이터 전송)
│
└── 3. 제어 커널 연산단 (Kernel Layer)
    └── [핵심 커널]: fluxmesh_motor_feedback_kernel
        ├── ▷ Pade Compression (신호 왜곡 최소화 및 고속 궤적 압축)
        └── ▷ Joseph Form Shield (필터링 수치 무결성 및 NaN 결함 방지 방어벽)
```

---
# ⚡ 소프트웨어 가드 및 물리 드라이버 (Failsafe & Driver)

### 1. 자율 세포 사멸 (Apoptosis)
* **메커니즘**: 센서 데이터에서 `NaN` 결함이 감지되는 즉시 해당 노드를 강제 사멸 처리함
* **부하 절감**: 사멸된 노드는 `-99.0f` 거부 신호를 송신하여 중앙 마스터 보드의 연산 부하를 실시간으로 감소시킴

### 2. 12비트 물리 출력 드라이버 (Teensy/Arduino)
* **지터 제어**: 50Hz 독립 레지스터 기반의 순수 정수 연산을 통해 물리 제어 신호의 지터 노이즈를 제어함
* **텐던 인장**: `0` ~ `4095` 단계(12비트 해상도)의 정밀한 스텝 수식으로 다이니마 텐던 메커니즘의 인장력을 정밀 구동함

---

# 📂 저장소 구조 (Repository Architecture)

```text
repository_root/
├── 📁 01_Full_Loss_Standard/
│   └── 5지 독립 구동 파라메트릭 도면 및 가속 융합 커널
└── 📁 02_Hybrid_Partial_Loss/
    └── 15도 사선형 관통 홀 기반 미러링 추적 커널
```

---

# 💻 컴파일러 규칙 (Compiler Flag)

```bash
# ⚠️ 경고: -ffast-math 및 -Ofast 옵션 사용 절대 금지! 
# 커널 내부의 IEEE 754 표준 가드(NaN 체크 코드) 무결성 유지를 위해 반드시 -O2 또는 -O3 빌드 플래그만 사용하십시오.
```

---


## 📜 라이선스 (License)

- **Software**: GNU GPLv3
- **Hardware**: CERN-OHL-W v2
