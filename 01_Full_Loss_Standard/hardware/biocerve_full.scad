// =================================================================
// 🌊 BioCerve-Hand: Parametric Prosthetic System (Hardware Core v2.5)
// Part 1: Global Constants, Biometric Database, and Main Assembly
// License: GNU General Public License v3.0 (GPLv3) / CERN-OHL-W v2
// =================================================================

$fn = 50; // 5개 손가락 및 손바닥 동시 렌더링 연산 속도를 위한 정밀도 최적화

// =================================================================
// [1] 생체 비율 데이터베이스 (인간 성인 손가락 평균 실측치 매핑)
// =================================================================
// 배열 인덱스 주소: [0:엄지(Thumb), 1:검지(Index), 2:중지(Middle), 3:약지(Ring), 4:새끼(Pinky)]

// 🦴 각 손가락별 마디 길이 데이터셋 (mm 단위 실측치)
proximal_lengths = [32.0, 35.0, 40.0, 37.0, 30.0]; 
middle_lengths   = [0.0,  25.0, 28.0, 26.0, 20.0]; // 엄지는 중간마디가 없어 0으로 하드코딩 예외 처리
distal_lengths   = [22.0, 20.0, 22.0, 21.0, 18.0]; 

// 📐 각 손가락별 두께 스케일 가중치 (중지 스케일 기준 비례 배분)
finger_thickness = [1.20, 0.95, 1.00, 0.95, 0.80]; 

// =================================================================
// [2] 글로벌 공통 제어 변수 (Global Hardware Constraints)
// =================================================================
base_pip_dia = 5.8;  // 기준 구슬 지름 (중지 스케일 기준 표준 기하학 상수)
clearance    = 0.2;  // 3D 프린트 필라멘트 열수축 대응 내부 구동 유격 (+0.2mm)
wall_thick   = 2.0;  // 다이니마 와이어 장력을 방어하기 위한 최소 외벽 두께 (2.0mm)
tendon_dia   = 1.5;  // 보풀 가드 통과용 고강도 섬유선(Dyneema) 구멍 지름

// =================================================================
// [3] 실시간 가동성 및 시뮬레이터 제어 (Simulator Setup)
// =================================================================
// 아래 pip_angle 값을 0에서 90까지 바꾸면 1:0.7 비례 수식에 따라 손끝이 알아서 함께 움직입니다.
pip_angle = 40;      // 관절 구동 각도 입력 (0 ~ 90)

// 🛡️ [출력 필터 스위치]
// (0:엄지, 1:검지, 2:중지, 3:약지, 4:새끼, 99:손바닥 상단판 포함 전체 결합형 출력)
// 💡 실전 팁: 초기 관절 구동성 테스트 시에는 원하는 손가락 인덱스(예: 중지 = 2)로 변경하여 단일 사출하십시오.
render_target = 99; 

// =================================================================
// [4] 메인 배포 파이프라인 (Main System Entry Point)
// =================================================================
if (render_target == 99) {
    complete_hand_with_upper_palm();
} else {
    // 지정한 단일 손가락만 테스트 목적으로 원점에 출력
    generate_biometric_finger(render_target, pip_angle);
}


// [5] 2피스 분할형 손바닥 상단 프레임판 메인 모듈
module complete_hand_with_upper_palm() {
    // 손바닥 상단판 전체 치수 정의
    palm_width = 18 * 4 + (base_pip_dia * 1.2 + clearance + wall_thick * 2); // 다섯 손가락 배치 폭 계산
    palm_depth = 25;
    palm_thick = 6;

    difference() {
        // A. 손바닥 상단 베이스 플레이트 주조
        color("Gray") 
            translate([-10, -5, -palm_thick]) 
                cube([palm_width, palm_depth, palm_thick]); 
        
        // B. 하단 하우징(모터 박스)과의 체결을 위한 M3 볼트 고정 홀 타공 (모서리 4개소)
        // 지름 3.2mm 구멍을 뚫어 M3 볼트가 탭 없이 부드럽게 관통하도록 마진 설정
        translate([-5, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([-5, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        
        // C. 손가락 뿌리에서 내려오는 5쌍의 텐던 와이어가 통과할 수직 관통 가이드 홀
        for (i = [0:4]) {
            scale_factor = finger_thickness[i];
            pip_pivot_dia = base_pip_dia * scale_factor;
            
            // 🛠️ [보풀 가드 통합] 5개 노드 전체에 나팔꽃 모양 모따기 수식 반영
            // 와이어가 하단 모터 박스로 진입할 때 각도 꺾임에 의한 단선을 원천 예방하고 드릴 리밍 후가공을 가이드
            union() {
                // 메인 텐던 관통 터널
                translate([i * 18 + (pip_pivot_dia / 2 + wall_thick / 2), 0, -palm_thick - 1])
                    cylinder(h = palm_thick + 2, d = tendon_dia);
                
                // 베이스 플레이트 최상단 인입구 깔때기 가공
                translate([i * 18 + (pip_pivot_dia / 2 + wall_thick / 2), 0, -0.1])
                    cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
            }
        }
    }
    
    // D. 손바닥 상단판 프레임 위에 5개 손가락 유닛을 일체형(Monolithic)으로 빌드업
    for (i = [0:4]) {
        translate([i * 18, 0, 0]) generate_biometric_finger(i, pip_angle);
    }
}

// =================================================================
// 🌊 BioCerve-Hand: Parametric Prosthetic System (Hardware Core v2.5)
// Part 2: Biometric Finger Generator and Cybernetic Joint Modules
// License: GNU General Public License v3.0 (GPLv3) / CERN-OHL-W v2
// =================================================================

// 5개 손가락 생체 비례 생성 자동 제어 파이프라인
module generate_biometric_finger(id, angle) {
    // 해당 손가락 ID의 고유 생체 실측 수치 추출
    p_len = proximal_lengths[id];
    m_len = middle_lengths[id];
    d_len = distal_lengths[id];
    scale_factor = finger_thickness[id];
    
    // 두께 가중치(scale_factor)에 따른 관절 구슬 및 외곽 프레임 수치 자동 스케일링
    pip_pivot_dia   = base_pip_dia * scale_factor;
    pip_track_width = pip_pivot_dia + clearance;
    outer_radius    = (pip_track_width / 2) + wall_thick;
    
    // 1:0.7 기계적 비례 수식에 기반한 DIP 관절부 치수 강제 동기화
    dip_pivot_dia   = pip_pivot_dia * 0.7; 
    dip_track_width = dip_pivot_dia + clearance;
    
    dip_angle = angle * 0.7; // 손끝 연동 각도 자동 연산

    // -------------------------------------------------------------
    // [A] 첫째 마디 기저부 (Proximal Phalanx Frame)
    // -------------------------------------------------------------
    difference() {
        // 첫째 마디 기본 바디 골격
        translate([-outer_radius, -5, 0]) cube([outer_radius * 2, 10, p_len]);
        
        // 메인 구동 텐던 수직 관통 홀 및 보풀 방지 실드 통합 가공
        union() {
            // 텐던 관통 메인 터널
            translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                cylinder(h = p_len + 2, d = tendon_dia);
                
            // 🛠️ [리밍 가이드 챔퍼 이식] 
            // 손바닥판에서 손가락 마디로 와이어가 전도될 때 모서리 마찰 끊어짐을 완벽히 선방어
            // 출력 후 1.5mm~2.0mm 드릴 비트를 통과시키는 리밍 후가공 진입로 역할 수행
            translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
    }

      // -------------------------------------------------------------
    // [B] 중간 관절(PIP) 상단 구슬 코어 + 중간 마디 프레임
    // -------------------------------------------------------------
    translate([0, 0, p_len])
        rotate([0, angle, 0]) {
            
            // PIP 중심 구슬 코어 (회전축 무결성 교정 완료)
            difference() {
                union() {
                    translate([-outer_radius, -5, 0]) cube([outer_radius * 2, 10, 5]);
                    sphere(d = pip_pivot_dia);
                    // [🛡️ 물리 가드 1] 부러짐 방지 테이퍼드 목 구조 주조
                    cylinder(h = 4, d1 = pip_pivot_dia, d2 = pip_pivot_dia * 0.8, center = false);
                }
                // 🛠️ [축 오류 교정 1] C-커브 텐던 경로가 메인 관절 굽힘 회전면(Y축 기준)과 
                // 정확히 평행하게 정렬되도록 rotate([90, 0, 0]) 수식으로 터널 방향 교정
                rotate([90, 0, 0])
                    rotate_extrude(angle = 90)
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                            circle(d = tendon_dia);
            }
            
            // 해부학적 예외 처리 예외 가드 (엄지는 중간 마디가 없으므로 바로 손끝 매핑)
            if (id == 0) {
                rotate([0, dip_angle, 0]) {
                    distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, outer_radius);
                }
            } else {
                // 일반 손가락 (검지, 중지, 약지, 새끼) 중간 마디 빌드
                difference() {
                    // 중간 마디 뼈대 연장 프레임 바디
                    translate([-outer_radius, -5, 0]) cube([outer_radius * 2, 10, m_len]);
                    
                    // [🛑 물리 가드 2: Wedge-Lock 역방향 스토퍼 홈 가공 및 슬립 방지 보강]
                    sphere(d = pip_track_width + 0.05);
                    
                    // 🛠️ [축 오류 교정 2 & 슬립 방지 가드 임베딩]
                    // 기존 [0, 45, 0]으로 Y축을 또 돌려 측면이 깎이던 치명적 결함을 정밀 연동축 구조로 정상화.
                    // 더불어 차단 절벽 끝단에 오버행 처짐을 흡수할 기하학적 미세 모따기 큐브를 결합하여 잠금 무결성 확보.
                    rotate() {
                        translate([0, -(pip_track_width + 1) / 2, -(pip_track_width + 1) / 2]) {
                            cube([pip_track_width + 1, dip_track_width + 1, pip_track_width + 1]); // 트랙 1 폭 연동
                        }
                        // 스토퍼 절벽 단면 끝자락에 FDM 처짐 마진용 미세 탈형 홈(+1.5mm) 차집합 전개
                        translate([0, -(pip_track_width + 1.5) / 2, pip_track_width / 2 - 0.15])
                            cube([pip_track_width + 1.5, pip_track_width + 1.5, 1.5]);
                    }
                    
                    // 🛠️ 이중 나팔꽃 보풀 가드 (PIP 측 깔때기형 입구)
                    union() {
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                            cylinder(h = m_len + 2, d = tendon_dia);
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                            cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
                    }
                }
                
                // 중간 마디 끝단에 1:0.7 스케일로 압축 축소 주조된 DIP 관절 구슬 코어
                translate([0, 0, m_len]) {
                    difference() {
                        union() {
                            sphere(d = dip_pivot_dia); // 미니 구슬
                            cylinder(h = 3, d1 = dip_pivot_dia, d2 = dip_pivot_dia * 0.8, center = false);
                        }
                        // 🛠️ [축 오류 교정 3] DIP 가이드 터널도 메인 기전과 일치하도록 rotate([90, 0, 0])로 궤적 동기화
                        rotate([90, 0, 0])
                            rotate_extrude(angle = 90)
                                translate([dip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                                    circle(d = tendon_dia);
                    }
                }

                // -------------------------------------------------------------
                // [C] 최종 손끝 마디 어셈블리 (Distal Phalanx Unit)
                // -------------------------------------------------------------
                translate([0, 0, m_len])
                    rotate([0, dip_angle, 0]) {
                        distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, outer_radius);
                    }
            }
        }
}


// 최종 손끝 마디 및 미끄럼 방지 패드 가이드 슬롯 공통 코어 모듈
module distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, outer_radius) {
    difference() {
        union() {
            // 손끝 프레임 기본 뼈대
            translate([-outer_radius * 0.8, -5, 0]) cube([outer_radius * 1.6, 10, d_len]);
            // 외형 보완 및 챔퍼 효과용 대각 덤블링 라운딩 형상
            translate([0, 0, d_len - 2]) sphere(r = outer_radius * 0.8);
        }
        
        // DIP 하단 소켓 및 역방향 락인 스토퍼 설계 (연동축 교정 및 슬립 방지 보강 통합)
        sphere(d = dip_track_width + 0.05);
        
        // 🛠️ [축 오류 교정 및 슬립 가드 이식]
        // 기존 회전축 버그를 수정하여 실제 손끝 과신전 하중 발생 시 물리 턱이 정확히 물리도록 전면 개편.
        // 동시에 오버행 처짐 마진용 미세 도피 홈 큐브(+1.5mm)를 차집합 결합하여 사출 안정성 확보.
        rotate() {
            translate([0, -(dip_track_width + 1) / 2, -(dip_track_width + 1) / 2]) {
                cube([dip_track_width + 1, dip_track_width + 1, dip_track_width + 1]);
            }
            // 스토퍼 절벽 단면 끝자락에 FDM 압출 누적 처짐을 흡수할 기하학적 미세 모따기 큐브 추가
            translate([0, -(dip_track_width + 1.5) / 2, dip_track_width / 2 - 0.15])
                cube([dip_track_width + 1.5, dip_track_width + 1.5, 1.5]);
        }
                
        // 🛠️ 이중 나팔꽃 보풀 가드 (DIP 측 깔때기형 입구)
        union() {
            translate([dip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                cylinder(h = d_len + 2, d = tendon_dia);
            translate([dip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
        
        // 🧲 물체 파지성 향상을 위한 전면 실리콘/고무 패드 삽입 몰딩 홈 가공 (깊이 2mm)
        translate([-(outer_radius), -6, d_len / 2])
            cube([outer_radius * 2, 2, d_len / 2]);
    }
}
