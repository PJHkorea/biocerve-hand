# 아직 작업중

# 🧬 BioCerve-Hand: Parametric Hardware Core (v9.1)

> **Split-Shell 3D-Printed Prosthetic Chassis Featuring Pin-Assembled Roller Bearings & Dyneema-Optimized Tendon Guides.**

본 프로젝트는 분산형 제어 커널인 `fluxmesh-cybernetics-kernel`과 1:1로 물리적 좌표계가 동기화되어 작동하는 성인 손 생체 비례 맞춤형 파라메트릭 의수 하드웨어 설계 청사진입니다.

기존 일체형 사출 방식에서 빈번히 발생하는 출력 부품 간의 엉겨 붙음 현상을 개선하고자, 좌우 분할 커버 쉘(Split-Shell) 구조와 실물 고정 핀 및 빨대 부싱 롤러 메커니즘을 결합했습니다. 이를 통해 3D 프린팅 특유의 적층 단면 마찰(Shear Edge)로 인한 와이어 단선 문제를 보완하고자 노력했습니다. 비교적 저렴한 오픈소스 재료들을 효율적으로 활용하여 준수한 생체 내구성과 5지 독립 구동 성능을 구현하는 것을 목표로 합니다.

본 하드웨어 소스코드(`Fingers_default.scad`, `thumb_default.scad`) 및 제조 청사진은 **GNU General Public License v3.0 (GPLv3)** 및 **CERN Open Hardware Licence Version 2 (CERN-OHL-W v2)** 하에 배포되며, 인류의 공공재로서 자유롭게 활용하고 발전시켜 나가실 수 있습니다.

---

## 📐 3대 핵심 기계공학 매커니즘 (Mechanical Primitives)

### 1. 파라메트릭 인체 비율 스케일링 & 해부학 예외 가드 (Biometric Scaling)
* **기하학 가중치 동기화**: 마스터 두께 변수(`finger_w`) 하나만 정의하면 첫째마디(1.8배), 중간마디(0.7배), 끝마디(0.5배) 길이와 관절 구슬 크기(`joint_radius`)가 인체의 해부학적 비율에 맞추어 자동으로 스케일 다운(Scale-down)되도록 설계되었습니다.
* **엄지손가락 2마디 독립 최적화**: 중간 마디가 없는 엄지손가락(`thumb_default.scad`)의 구조적 특성을 반영하여 초기 첫 마디와 둘째마디까지 완성한 구조에서 완료했습니다.
* 엄지 제외 4개 손가락은 (`Fingers_default.scad`)에서 비율만 수정해 출력하기 쉽도록 설계했습니다.

### 2. 좌우 분할 조립식 구슬 락-인 관절 (Split-Shell & Wedge-Lock)
* **출력 안정성 확보**: 관절 부위가 열로 인해 서로 붙어버리는 사출 불량을 줄이기 위해, 손가락 프레임을 좌우 커버 쉘로 분할 사출한 후 가로 정중앙 X축 관통 메인 핀(`pin_dia = 2.0`)으로 체결하는 구조를 채택했습니다.
* **기계적 과신전 방어**: 정상 구동 범위($0^\circ \sim 90^\circ$) 안에서는 정밀 조립 공차(`clearance = 0.25`)를 통해 부드럽게 주행합니다. 외력에 의해 과신전 하중이 발생할 경우, 플라스틱 후방 스토퍼 턱(`stopper_thick = 3`)들이 물리적으로 맞물려 지지해 주는 Wedge-Lock 가드가 작동합니다.

<img style="width: 50%;" alt="image" src="https://github.com/user-attachments/assets/3bbda816-712c-4d4d-97a2-c4b09caf3bb5" /> 
<img style="width: 50%;" height="708" alt="image" src="https://github.com/user-attachments/assets/c5051dc6-5d06-4fb0-9cbc-e089ef202d33" />


### 3. 블록 내 정밀 좌표 매립형 빨대 롤러 가이드 (Anchor-Positioned Roller Core)
* **단선 마모 보완**: 와이어 가이드 터널 출구에서 발생하는 날카로운 마찰을 줄이기 위해, 관절 내부 공간에 쇠봉과 빨대 조각을 결합한 자율 회전 롤러 부싱을 매립하는 방식을 제안합니다.
* **기하학적 텐던 접선 정렬**: 롤러 블록이 와이어를 접선(Tangent) 방향으로 안정적으로 받쳐줄 수 있도록 블록 내부에 계산된 고정 배치 좌표(`target_pin_y`, `target_pin_z`)를 지정했습니다. 와이어가 플라스틱 단면에 직접 닿기 전에 롤러 표면이 궤적을 바깥으로 완만하게 유도하여 다이니마(Dyneema) 섬유선의 수명 향상을 도모했습니다.

---

## 🖨 3D 프린팅 실전 사출 규칙 & 트러블슈팅 (v9.1 Slicing Instruction)

* **소재 및 슬라이싱 사양**: 몸체 프레임은 PETG 또는 고강도 PLA+ 사용을 권장합니다. 관절 핀 홀 주변과 와이어 가이드 터널 경로는 내부 채움(Infill) 비율에만 의존하기보다, 외벽 루프(Wall Lines / Perimeters) 개수를 최소 5~6회 이상(2.0mm 이상 스킨)으로 설정하여 해당 부위의 물리적 강도를 충분히 확보해 주십시오.
* **레이어 적층 방향**: 핀 홀 주변의 전단 하중으로 인한 파손을 방지하기 위해 부품을 옆으로 완전히 뉘어서 사출하거나, 45도 기울여 슬라이싱하시는 것을 권장합니다.
* **외관 실리콘 스킨 복원력 연동**: 본 설계는 손등 쪽의 번거로운 기계적 고무줄 링케이지 구조를 과감히 생략했습니다. 의수 외관에 씌워질 실리콘 케이스(경도 Shore A 10~15 부가형 실리콘 권장) 고유의 복원 탄성을 활용하도록 설계되었습니다. 모터가 전류를 해제하고 인장선을 푸는 즉시, 실리콘 스킨의 수축력에 의해 자연스러운 반굴곡 상태의 휴식위(Resting Position)로 부드럽게 복귀합니다.

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

### 1. 자율 세포 사멸 및 소용돌이 우회장 (Apoptosis & Vorticity Reroute)
*   **자가 치유 메커니즘**: 말초 신경 노드에서 단선, 전압 폭주 등으로 인한 **NaN(Not a Number)** 오염 감지 시, 카운터 가드가 작동하여 해당 노드를 시너지 풀에서 즉시 사멸 격리(-99.0f) 처리합니다.
*   **물리적 순응성(Compliance)**: 사멸된 노드가 차단되면 중앙 커널은 무거운 미분 연산 없이 **살아남은 정상 노드로 제어 지분을 실시간 사선 우회(Reroute)** 시킵니다. 이 분모 압축 트릭 덕분에 복잡한 인공지능 없이도 의수가 물체 형상에 맞춰 스스로 손가락을 휘감아 쥐는 기계적 적응성이 수학적으로 완성됩니다.

### 2. 12비트 물리 출력 드라이버 (Teensy / Arduino Register Binding)
*   **물리 지터 노이즈 제어**: 서보 모터의 제어 주파수(50Hz)를 MCU 타이머 레지스터에 하드웨어적으로 고정하고, 1kHz 메인 펌웨어 주기와 동기화하여 모터가 파지 도중 덜덜 떨리는 지터(Jitter) 현상을 원천 차단합니다.
*   **텐던 인장 정밀도 극상화**: 일반적인 8비트(0~255) 제어를 탈피하여 **0 ~ 4095 단계의 12비트 고해상도 물리 레지스터 제어**를 집행합니다. 순수 정수 비례 사칙연산만으로 다이니마 텐던 와이어의 미세 인장 길이를 소용돌이 변수 수준으로 정밀 제어합니다.

---

# 📂 저장소 구조 (Repository Architecture)

```text
repository_root/
├── 📁 01_Full_Loss_Standard/              # [트랙 1] 손 전체 소실 표준 패키지
│   ├── 📁 hardware/
│   │   ├── 📜 README.md                    # FDM 사출 세팅 및 100% Solid 인필 블로커 가이드
│   │   └── 📐 biocerve_full.scad           # v2.5 교정축 수동 락인(Wedge-Lock) 통합 도면
│   └── 📁 software/
│       ├── 📜 README.md                    # 컴파일러 가드(-ffast-math 금지) 및 아키텍처 명세
│       ├── ⚙️ fluxmesh_motor_feedback_kernel.h # Joseph Form 공분산 실드 및 사멸 제어 헤더
│       └── 🔌 fluxmesh_integrated_prototype.cpp # 12비트 물리 타이머 매핑 및 1kHz 실시간 파이프라인
│
└── 📁 02_Hybrid_Partial_Loss/             # [트랙 2] 일부 소실 환자용 하이브리드 패키지
    ├── 📁 hardware/
    │   ├── 📜 README.md                    # 슬롯 서포터 차단(Support Blocker) 및 후가공 가이드
    │   └── 📐 biocerve_hybrid.scad         # 동적 마스킹 및 15도 인체공학적 경사 관통 홀 도면
    └── 📁 software/
        ├── 📜 README.md                    # 생체 신호 미러링 가이드 및 셋업 매뉴얼
        ├── ⚙️ biocerve_hybrid_core.h        # 미러링 소용돌이 우회장(Vorticity) 통합 제어 헤더
        └── 🔌 biocerve_hybrid_prototype.cpp  # 12비트 타이머 바인딩 및 1kHz 실시간 미러링 실행 파일

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
