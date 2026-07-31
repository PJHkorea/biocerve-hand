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
pip_angle = 90;      // 관절 구동 각도 입력 (0 ~ 90)

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
        translate([-5, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([-5, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        
        // C. 손가락 뿌리에서 내려오는 5쌍의 텐던 와이어가 통과할 수직 관통 가이드 홀
        for (i = [0:4]) {
            scale_factor = finger_thickness[i];
            pip_pivot_dia = base_pip_dia * scale_factor;
            
            // 각 손가락 배치 간격 (18mm)에 맞춰 좌표 계산 후 수직 관통 구멍 가공
            translate([i * 18, palm_depth / 2, -palm_thick - 1]) {
                // 1. 메인 와이어 관통 터널 (Dyneema 선 통과용)
                cylinder(h = palm_thick + 2, d = tendon_dia);
                
                // 2. 상단 나팔꽃 깔때기 가이드
                translate([0, 0, palm_thick - 1.1])
                    cylinder(h = 2.3, d1 = tendon_dia, d2 = tendon_dia + 1.5, center = false);
                
                // 3. 하단 나팔꽃 깔때기 가이드
                translate([0, 0, -0.1])
                    cylinder(h = 2.3, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
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
// Part 1: Global Constants, Biometric Database, and Main Assembly
// License: GNU General Public License v3.0 (GPLv3) / CERN-OHL-W v2
// =================================================================

$fn = 50; // 5개 손가락 및 손바닥 동시 렌더링 연산 속도를 위한 정밀도 최적화

// =================================================================
// [1] 생체 비율 데이터베이스 (인간 성인 손가락 평균 실측치 매핑)
// =================================================================
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
pip_angle = 0;      // 관절 구동 각도 입력 (0 ~ 90)
render_target = 99; 

// =================================================================
// [4] 메인 배포 파이프라인 (Main System Entry Point)
// =================================================================
if (render_target == 99) {
    complete_hand_with_upper_palm();
} else {
    generate_biometric_finger(render_target, pip_angle);
}

// =================================================================
// [5] 2피스 분할형 손바닥 상단 프레임판 메인 모듈
// =================================================================
module complete_hand_with_upper_palm() {
    palm_width = 18 * 4 + (base_pip_dia * 1.2 + clearance + wall_thick * 2) + 5;

    palm_depth = 25;
    palm_thick = 6;

            difference() {
        // A. 손바닥 상단 베이스 플레이트 주조
        // 🛠️ [좌측 여백 버그 완전 박멸]: 수동 오프셋 대신 손바닥 실제 폭(palm_width)의 
        // 정확한 절반 정중앙을 원점으로 매핑하여 엄지손가락 밑바닥까지 살집을 완벽히 채워줍니다.
                color("Gray") 
            // 🛠️ [플레이트 쏠림 최종 박멸]: 손가락 배치 원점 축에 정확히 일치하도록 X축 중심점을 -22으로 원상 복구 및 최적화합니다.
            translate([palm_width / 2 -22, palm_depth / 2, -palm_thick / 2]) 
                cube([palm_width, palm_depth, palm_thick], center = true); 


        
               // B. 하단 하우징(모터 박스)과의 체결을 위한 M3 볼트 고정 홀 타공 (모서리 4개소 완전 파라메트릭 제어)
        // 💡 플레이트의 마스터 이동축(-22)과 완벽하게 일치시켜 볼트 홀이 모서리 안전 마진을 유지하도록 교정합니다.
        let (margin_x = 4, margin_y = 4) {
            // 좌측 상단 볼트 홀
            translate([-22 + margin_x, margin_y, -palm_thick - 1]) 
                cylinder(h = palm_thick + 2, d = 3.2);
                
            // 우측 상단 볼트 홀
            translate([palm_width - 22 - margin_x, margin_y, -palm_thick - 1]) 
                cylinder(h = palm_thick + 2, d = 3.2);
                
            // 좌측 하단 볼트 홀
            translate([-22 + margin_x, palm_depth - margin_y, -palm_thick - 1]) 
                cylinder(h = palm_thick + 2, d = 3.2);
                
            // 우측 하단 볼트 홀
            translate([palm_width - 22 - margin_x, palm_depth - margin_y, -palm_thick - 1]) 
                cylinder(h = palm_thick + 2, d = 3.2);
        }
        
        // C. 손가락 뿌리에서 내려오는 5쌍의 텐던 와이어가 통과할 수직 관통 가이드 홀
        for (i = [0:4]) {
            scale_factor = finger_thickness[i];
            pip_pivot_dia = base_pip_dia * scale_factor;
            
            // 🛠️ [궤적 정밀 도킹]: 현재 화면에서 가장 완벽하게 안착해 있는 손가락들의 기본 생성 오프셋에 맞추어 
            // 와이어 가이드 타공 축의 X축 시작점 마진을 정교하게 고정합니다. (손가락 튕김을 완벽히 방어)
            translate([i * 18 - 14 + (pip_pivot_dia / 2 + wall_thick / 2), palm_depth / 2, -palm_thick - 1]) {
                // 1. 메인 와이어 관통 터널 (Dyneema 선 통과용)
                cylinder(h = palm_thick + 2, d = tendon_dia);
                // 2. 베이스 플레이트 최상단 인입구 깔때기 가공
                translate([0, 0, palm_thick - 1.1])
                    cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
            }
        }

    }
    
    // D. 손바닥 상단판 프레임 위에 5개 손가락 유닛을 일체형(Monolithic)으로 빌드업
    // 🛠️ [최종 정중앙 안착]: 손가락의 X축 생성 원점도 -14로 고정하여 좌우 여백의 밸런스를 완벽한 대칭형으로 마감합니다.
    for (i = [0:4]) {
        translate([i * 18 - 14, palm_depth / 2, 0]) 
            generate_biometric_finger(i, pip_angle);
    }
}


// =================================================================
// [6] 손가락 생체 비례 생성 자동 제어 파이프라인
// =================================================================
module generate_biometric_finger(id, angle) {
    p_len = proximal_lengths[id];
    m_len = middle_lengths[id];
    d_len = distal_lengths[id];

    scale_factor = finger_thickness[id];
    
    pip_pivot_dia   = base_pip_dia * scale_factor;
    pip_track_width = pip_pivot_dia + clearance;
    outer_radius    = (pip_track_width / 2) + wall_thick;
    dip_pivot_dia   = pip_pivot_dia * 0.7;
    dip_track_width = dip_pivot_dia + clearance;
    
    dip_angle = angle * 0.7;

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
                
            // 리밍 가이드 챔퍼 이식
            translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
    }

    // -------------------------------------------------------------
    // [B] 중간 관절(PIP) 상단 구슬 코어 + 중간 마디 프레임
    // -------------------------------------------------------------
    // 뼈대 및 관절 실시간 행렬 변환 제어부
    translate([0, 0, p_len]) {
        rotate([0, angle, 0]) {
            
            // PIP 중심 구슬 코어 (차집합 괄호 꼬임 완전 교정)
            difference() {
                union() {
                    translate([-outer_radius, -5, 0]) cube([outer_radius * 2, 10, 5]);
                    sphere(d = pip_pivot_dia);
                    cylinder(h = 4, d1 = pip_pivot_dia, d2 = pip_pivot_dia * 0.8, center = false);
                }
                // C-커브 텐던 경로 터널 가공
                rotate([90, 0, 0])
                    rotate_extrude(angle = 90)
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                            circle(d = tendon_dia);
                            
                // 🛠️ 교정: 진입로 이중 나팔꽃 깔때기를 difference 안으로 편입하여 정확하게 깎아냄
                translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                    cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
            }
            
                                   // 🛠️ 엄지손가락 최종 교정: 불필요한 Y축 수동 오프셋을 걷어내고 회전축 정중앙 원점 정렬
            if (id == 0) {
                let (
                    thumb_dip_pivot = pip_pivot_dia * 0.7,
                    thumb_dip_track = pip_track_width * 0.7
                ) {
                    translate([0, 0, 0]) { // 👈 편심을 유발하던 나눗셈 좌표를 0으로 초기화
                        rotate([0, angle, 0]) { 
                            distal_fingertip_core(d_len, thumb_dip_pivot, thumb_dip_track, outer_radius);
                        }
                    }
                }
            }

 else {
                // 일반 손가락 (검지, 중지, 약지, 새끼) 중간 마디 빌드
                difference() {
                    translate([-outer_radius, -5, 0]) cube([outer_radius * 2, 10, m_len]);
                    sphere(d = pip_track_width + 0.05);
                    
                    rotate([0, angle, 0]) { 
                        // 깨끗하게 정돈된 소켓 중앙 오프셋 및 큐브 차집합 연산
                        translate([0, -(dip_track_width + 1) / 2, 0])
                            cube([pip_track_width + 1, dip_track_width + 1, pip_track_width + 1]);
                        
                        translate([0, -(pip_track_width + 1.5) / 2, pip_track_width / 2 - 0.15])
                            cube([pip_track_width + 1.5, pip_track_width + 1.5, 1.5]);
                    }
                    
                    union() {
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                            cylinder(h = m_len + 2, d = tendon_dia);
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                            cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
                    }
                }
                
                // 중간 마디 끝단 DIP 관절 구슬 코어
                translate([0, 0, m_len]) {
                    difference() {
                        union() {
                            sphere(d = dip_pivot_dia); 
                            cylinder(h = 3, d1 = dip_pivot_dia, d2 = dip_pivot_dia * 0.8, center = false);
                        }
                        rotate([90, 0, 0])
                            rotate_extrude(angle = 90)
                                translate([dip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                                    circle(d = tendon_dia);
                    }
                }

                              // -------------------------------------------------------------
                // [C] 최종 손끝 마디 어셈블리 (Distal Phalanx Unit)
                // -------------------------------------------------------------
                // 🛠️ 최종 교정: 중간 마디 끝점으로 올려준 후, 정방향 각도(dip_angle)로 관절 구슬 중심 회전 집행
                               // 🛠️ 최종 궤적 결합: X축 편심을 0으로 원점 정렬하고, 중간 마디 끝에서 정방향 회전
                translate([0, 0, m_len]) {
                    rotate([0, dip_angle, 0]) {
                        distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, outer_radius);
                    }
                }


            } 
        } 
    }
}


// 최종 손끝 마디 및 미끄럼 방지 패드 가이드 슬롯 공통 코어 모듈
module distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, outer_radius) {
    difference() {
        // 더할 형상 (손끝 전체 외형 프레임)
        union() {
            // 🛠️ [축 분리형 정밀 정렬]: X와 Y는 완벽한 대칭 중심(0)에 두고, Z축은 바닥(0)에서 시작해 위로 자라나도록 교정
            translate([-outer_radius * 0.8, -outer_radius * 0.8, 0]) 
                cube([outer_radius * 1.6, outer_radius * 1.6, d_len]);
                
            // 외형 보완 및 챔퍼 효과용 대각 라운딩 형상
            translate([0, 0, d_len - 2]) sphere(r = outer_radius * 0.8);
        }
        
        // 뺄 형상 (DIP 하단 베어링 소켓)
        sphere(d = dip_track_width + 0.05);
        
        // [손끝 마디 내부 소켓 완전 일직선 및 스토퍼 교정]
        rotate() { 
            // Y축과 Z축은 중앙 정렬하되, X축 방향으로 밀어내어 회전 틈새 가공
            translate([ 0, 0, 0 ])
                cube([dip_track_width + 1, dip_track_width + 1, dip_track_width + 1], center = true);
            
            translate([ (dip_track_width + 1.5)/2, 0, dip_track_width / 2 - 0.15 ])
                cube([dip_track_width + 1.5, dip_track_width + 1.5, 1.5], center = true);
        }
        
        // 이중 나팔꽃 보풀 가드 (DIP 측 깔때기형 입구 수평 정렬)
        translate([dip_pivot_dia / 2 + wall_thick / 2, 0, 0]) {
            cylinder(h = d_len + 2, d = tendon_dia, center = true);
            translate([0, 0, -d_len / 2 - 0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
        
        // 물체 파지성 향상을 위한 전면 실리콘/고무 패드 삽입 몰딩 홈 가공 (깊이 2mm)
        // Y축 중심선에 정확히 일치하도록 center = true 기반 교정
        translate([-outer_radius, 0, d_len / 2])
            cube([2, outer_radius * 0.8, d_len / 2], center = true);
    }
}

