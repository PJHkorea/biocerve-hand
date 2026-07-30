# 🦾 biocerve-hand

**biocerve-hand**는 환자의 손상 상태 및 절단 부위에 맞춰 최적의 솔루션을 제공하는 **맞춤형 오픈소스 전동 및 하이브리드 의수 플랫폼**입니다. OpenSCAD 기반의 가변형 도면과 생체 신호 제어 소프트웨어를 포함하고 있습니다.

---

## 📌 주요 특징 (Key Features)

| 구분 | 01_Full_Loss_Standard (트랙 1) | 02_Hybrid_Partial_Loss (트랙 2) |
| :--- | :--- | :--- |
| **대상 환자** | 손목 이상 또는 손바닥 전체 소실 환자 | 특정 손가락 일부 소실 환자 |
| **구동 방식** | 5지(엄지~새끼) 완전 전동 구동 | 생체 손가락 + 전동 의수 하이브리드 |
| **주요 센서** | 근전도(EMG) 센서, 압력(FSR) 센서 | 굽힘(Flex) 센서 |
| **핵심 기술** | 실시간 파지력(Grip Force) 피드백 제어 | 생체 손가락 미러링(Mirroring) 알고리즘 |

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
│       └── biocerve_core.h    # 근전도(EMG)/압력(FSR) 기반 전체 제어 소스 코드
│
└── 02_Hybrid_Partial_Loss/    # [트랙 2] 손가락 일부 소실 환자용 (하이브리드)
    ├── hardware/
    │   └── biocerve_hybrid.scad # finger_status 변수 분기 및 생체 손가락 관통 홀 도면
    └── software/
        └── biocerve_hybrid_core.h # 굽힘 센서 기반 생체 미러링(Mirroring) 소스 코드
```

---

## 🛠️ 트랙별 상세 안내 (Track Details)

### 🤖 트랙 1: 손 전체 소실 환자용
* **하드웨어 (`biocerve_full.scad`)**
  * OpenSCAD 파라미터 설정을 통해 환자의 건측(정상 유무) 손 크기에 맞추어 1:1 스케일링이 가능합니다.
* **소프트웨어 (`biocerve_core.h`)**
  * 전완근 잔존 근육에서 발생하는 **근전도(EMG) 신호**를 분석하여 의수를 개폐합니다.
  * 물건을 잡을 때 **압력(FSR) 센서**의 피드백을 받아 물건이 미끄러지거나 부서지지 않도록 적정 파지력을 유지합니다.

### 🧬 트랙 2: 손가락 일부 소실 환자용
* **하드웨어 (`biocerve_hybrid.scad`)**
  * 코드 내부의 `finger_status` 변수 설정에 따라 절단된 손가락 위치에만 기계 메커니즘을 동적으로 배치합니다.
  * 남아있는 생체 손가락이 외부로 나와 정상적으로 기능할 수 있도록 **관통 홀(Thru-hole)** 설계가 반영되어 있습니다.
* **소프트웨어 (`biocerve_hybrid_core.h`)**
  * 정상 손가락이나 손목 관절에 부착된 **굽힘(Flex) 센서**의 움직임을 실시간 추적합니다.
  * 소실된 손가락 의수가 생체 손가락의 움직임 비율에 맞춰 자연스럽게 연동되는 **동기화 미러링 기술**을 구현합니다.

---

## 🚀 퀵 스타트 (Quick Start)

### 1. 하드웨어 빌드 (OpenSCAD)
1. [OpenSCAD 공식 홈페이지](https://openscad.org)에서 프로그램을 다운로드합니다.
2. 원하는 트랙의 `.scad` 파일을 엽니다.
3. 소스 코드 상단의 신체 치수 매개변수(Parameter)를 환자에 맞춤형으로 수정한 후 `F6`을 눌러 렌더링합니다.
4. `STL` 파일로 내보낸 후 3D 프린터로 출력합니다.

### 2. 소프트웨어 업로드 (Arduino/PlatformIO)
1. 사용 중인 메인보드(MCU) 환경에 맞춰 개발 환경을 준비합니다.
2. 각 트랙의 `core.h` 파일을 메인 스케치 파일에 포함(`include`)합니다.
3. 하드웨어 핀 맵(Pin Mapping)을 매칭한 후 보드에 펌웨어를 빌드 및 업로드합니다.

---

## 📜 라이선스 (License)

본 프로젝트는 자유로운 하드웨어/소프트웨어 생태계를 위해 아래 라이선스 표준을 준수합니다.

* **Software**: [GPLv3](LICENSE) - 소스 코드 수정 및 배포 시 동일 라이선스 적용 및 소스 코드 공개 의무.
* **Hardware**: [CERN-OHL-W v2](LICENSE) - 도면 수정, 배포 및 상업적 이용 시 소스(설계도) 공개 의무가 있는 약한 상호 호환 라이선스.
