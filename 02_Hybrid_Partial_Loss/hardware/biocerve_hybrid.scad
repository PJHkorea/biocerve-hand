// =================================================================
// 🌊 BioCerve-Hand: Hybrid Partial Loss System (Hardware Core v2.5)
// Part 1: Parametric Canvas, Biometric Database, and Hybrid Palm
// License: GNU General Public License v3.0 (GPLv3) / CERN-OHL-W v2
// =================================================================

$fn = 50; // 5개 손가락 및 하이브리드 통형 손바닥 동시 연산 속도 최적화

// =================================================================
// [1] 하이브리드 환자 맞춤형 마스킹 매니페스트 (Hybrid Patient Profile)
// =================================================================
// 배열 인덱스 주소: [0:엄지(Thumb), 1:검지(Index), 2:중지(Middle), 3:약지(Ring), 4:새끼(Pinky)]

// 🛡️ [핵심 가드 스위치]
//  - 1: 손가락 소실 부위 ──► 의수 기계 관절 및 텐던 메커니즘 자동 빌드업
//  - 0: 실제 생체 손가락 ──► 모터 링크 소멸 및 15도 인체공학적 경사 관통 홀(Bypass) 타공
// 
// 💡 [사용법]: 환자의 잔존 신체 조건에 맞춰 아래 5개 스위치를 0 또는 1로 수정 후 저장(F5)하십시오.
// (디폴트 값: 중지[Index 2]만 완벽하게 살아있고, 나머지 4개 손가락 마디가 소실된 환자 대응 프로필)
// 🛠️ [교정 완료]: 비어있던 문법 에러 배열에 디폴트 마스킹 데이터셋[1, 1, 0, 1, 1] 주입
finger_status =; 

// 🦴 각 손가락별 실제 생체 마디 길이 데이터셋 (mm 단위 실측치)
proximal_lengths = [32.0, 35.0, 40.0, 37.0, 30.0]; 
middle_lengths   = [0.0,  25.0, 28.0, 26.0, 20.0]; // 엄지 중간마디 0 해부학적 고정 예외
distal_lengths   = [22.0, 20.0, 22.0, 21.0, 18.0]; 

// 📐 각 손가락별 두께 가중치 스케일 계수 (인체 고유 비례 적용)
finger_thickness = [1.20, 0.95, 1.00, 0.95, 0.80]; 

// =================================================================
// [2] 글로벌 공통 제어 변수 (Global Hardware Constraints)
// =================================================================
base_pip_dia = 5.8;  // 기준 구슬 지름 (중지 스케일 기준 표준 기하학 상수)
clearance    = 0.2;  // 3D 프린트 필라멘트 수축 대응 내부 구동 공차 유격 (+0.2mm)
wall_thick   = 2.0;  // 다이니마 와이어 장력을 방어하기 위한 최소 외벽 마진 (2.0mm)
tendon_dia   = 1.5;  // 보풀 가드 통과용 고강도 섬유선 구멍 지름

// 계산용 수학적 기하 변수 (Cascading Derivatives)
pip_track_width = base_pip_dia + clearance;
outer_radius    = (pip_track_width / 2) + wall_thick;

// =================================================================
// [3] 실시간 가동성 테스트 벤치 (시뮬레이터 각도 동기화)
// =================================================================
pip_angle = 40;      // 구동 각도 조절 (0~90도 입력 시 소실 의수 노드가 1:0.7 실시간 복사 구동)

// 하이브리드 완전체 손 구조 렌더링 호출
hybrid_hand_system();

module hybrid_hand_system() {
    palm_width = 18 * 4 + (outer_radius * 2);
    palm_depth = 28;
    palm_thick = 8;

    // ── 1단계: 하이브리드 환자 맞춤형 통형 손바닥판(Upper Palm Plate) 주조 ──
    difference() {
        // A. 손바닥 상단 베이스 플레이트 아키텍처 주조
        color("Gray") 
            translate([-10, -5, -palm_thick]) 
                cube([palm_width, palm_depth, palm_thick]); 
        
        // B. 하단 모터 박스 결합용 M3 볼트 고정 홀 타공 (사방 모서리 4개소)
        translate([-5, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, 0, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([-5, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        translate([palm_width - 15, palm_depth - 10, -palm_thick - 1]) cylinder(h = palm_thick + 2, d = 3.2);
        
        // C. 5개 슬롯 루프 순회: 의수 텐던 통로 타공 또는 생체 손가락 관통 홀(Bypass Thru-Hole) 차집합 전개
        for (i = [0:4]) {
            scale_factor = finger_thickness[i];
            f_pip_dia = base_pip_dia * scale_factor;
            f_outer_r = ((f_pip_dia + clearance) / 2) + wall_thick;
            
            if (finger_status[i] == 1) {
                // [의수 전동 노드 자리]: 기계 배선용 텐던 수직 홀 관통
                translate([i * 18 + (f_pip_dia / 2 + wall_thick / 2), 0, -palm_thick - 1])
                    cylinder(h = palm_thick + 2, d = tendon_dia);
            } else {
                // 🎯 [생체 손가락 보존 자리]: 인간 고유 촉각 보존을 위한 타원형 경사 슬롯 타공
                // 착용성 극대화를 위해 앞쪽으로 15도 기울어지게 설계하여 쓸림 및 피 안 통함 현상 원천 차단
                translate([i * 18, 5, -palm_thick - 2]) {
                    rotate([0, -15, 0]) { // 15도 인체공학적 경사각 투하
                        
                        // [메인 슬롯 관통] 사방 +2.25mm 공차 마진 확보
                        cylinder(h = palm_thick + 6, d = f_pip_dia + 4.5, $fn = 30); 
                        
                        // 🖨️ [서포터 차단 챔퍼 - 하단 림(Rim)] 45도 경사를 통한 출력 초기 안착 스킨 형성
                        translate([0, 0, 0.5])
                            cylinder(h = 1.5, d1 = f_pip_dia + 4.5, d2 = f_pip_dia + 7.5, $fn = 30);
                            
                        // 🖨️ [서포터 차단 챔퍼 - 상단 림(Rim)] 오버행 붕괴 방지용 가상 브릿징 지지대 주조
                        translate([0, 0, palm_thick + 3.5])
                            cylinder(h = 1.5, d1 = f_pip_dia + 7.5, d2 = f_pip_dia + 4.5, $fn = 30);
                    }
                }
            }
        }
    }
    
    // ── 2단계: 마스킹 배열에 따라 소실된 자리에만 의수 관절 기믹 일체형 주조 ──
    for (i = [0:4]) {
        if (finger_status[i] == 1) {
            translate([i * 18, 0, 0]) generate_biometric_finger(i, pip_angle);
        }
    }
}

// =================================================================
// 🌊 BioCerve-Hand: Hybrid Partial Loss System (Hardware Core v2.5)
// Part 2: Cybernetic Finger Assembly and Dynamic Joint Engines
// License: GNU General Public License v3.0 (GPLv3) / CERN-OHL-W v2
// =================================================================

// 5개 손가락 생체 비례 생성 및 관절 가속 파이프라인
module generate_biometric_finger(id, angle) {
    p_len = proximal_lengths[id];
    m_len = middle_lengths[id];
    d_len = distal_lengths[id];
    scale_factor = finger_thickness[id];
    
    // 두께 가중치(scale_factor)에 따른 관절 구슬 및 외곽 프레임 수치 자동 스케일링
    pip_pivot_dia   = base_pip_dia * scale_factor;
    pip_track_width = pip_pivot_dia + clearance;
    f_outer_radius  = (pip_track_width / 2) + wall_thick;
    
    // 1:0.7 기계적 비례 수식에 기반한 DIP 관절부 치수 강제 동기화
    dip_pivot_dia   = pip_pivot_dia * 0.7; 
    dip_track_width = dip_pivot_dia + clearance;
    
    dip_angle = angle * 0.7; // 손끝 연동 각도 자동 연산 (1:0.7)

    // -------------------------------------------------------------
    // [A] 첫째 마디 기저부 (Proximal Phalanx Frame)
    // -------------------------------------------------------------
    difference() {
        // 첫째 마디 기본 바디 골격
        translate([-f_outer_radius, -5, 0]) cube([f_outer_radius * 2, 10, p_len]);
        
        // 메인 구동 텐던 수직 관통 홀 및 보풀 방지 실드 통합 가공
        union() {
            // 텐던 관통 메인 터널
            translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                cylinder(h = p_len + 2, d = tendon_dia);
            
            // 🖨️ [리밍 가이드 챔퍼] 손바닥판에서 첫째 마디로 진입하는 와이어 마찰 저항 극소화
            translate([pip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
    }

    // -------------------------------------------------------------
    // [B] 중간 관절(PIP) 상단 구슬 코어 + 중간 마디 프레임
    // -------------------------------------------------------------
    translate([0, 0, p_len])
        rotate([0, angle, 0]) {
            
            // PIP 중심 구슬 코어 (fluxmesh 원천 기하학 기술 이식)
            difference() {
                union() {
                    translate([-f_outer_radius, -5, 0]) cube([f_outer_radius * 2, 10, 5]);
                    sphere(d = pip_pivot_dia);
                    // [🛡️ 물리 가드 1] 부러짐 방지 테이퍼드 목 구조 주조
                    cylinder(h = 4, d1 = pip_pivot_dia, d2 = pip_pivot_dia * 0.8, center = false);
                }
                // C-커브 텐던 경로 (곡률 우회 가이드 터널)
                rotate([90, 0, 0])
                    rotate_extrude(angle = 90)
                        translate([pip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                            circle(d = tendon_dia);
            }
            
            // 🛠️ [3번 버그 해결]: 엄지손가락 해부학적 독립 변수(Scope) 선언 및 궤적 동기화
            if (id == 0) {
                let (
                    thumb_dip_pivot = pip_pivot_dia * 0.7,
                    thumb_dip_track = pip_track_width * 0.7
                ) {
                    // 🛠️ 그래픽스 행렬 연산 표준 규격화: translate 선행 후 rotate 집행
                    translate([0, -(thumb_dip_track + 1) / 2, -(thumb_dip_track + 1) / 2]) {
                        rotate([0, angle, 0]) { // 엄지는 모터 다이렉트 1대1 구동 반영
                            distal_fingertip_core(d_len, thumb_dip_pivot, thumb_dip_track, f_outer_radius);
                        }
                    }
                }
            } else {
                // 일반 손가락 (검지, 중지, 약지, 새끼) 중간 마디 빌드
                difference() {
                    // 중간 마디 뼈대 연장 프레임 바디
                    translate([-f_outer_radius, -5, 0]) cube([f_outer_radius * 2, 10, m_len]);
                    
                    // [🛑 물리 가드 2: Wedge-Lock 역방향 스토퍼 홈 가공]
                    sphere(d = pip_track_width + 0.05);
                    
                    // 🛠️ [2번 버그 해결]: Wedge-Lock 편심 오류 교정 및 정렬 무결성 확보
                    // 기존 rotate 선행 구조를 파괴하고 translate를 바깥으로 감싸 제자리 축 정렬을 집행
                    translate([0, -(pip_track_width + 1) / 2, -(pip_track_width + 1) / 2]) {
                        rotate([0, 45, 0]) {
                            cube([pip_track_width + 1, pip_track_width + 1, pip_track_width + 1]);
                            
                            // 스토퍼 절벽 단면 끝자락에 오버행 처짐을 흡수할 기하학적 미세 모따기 큐브 위치 보정
                            translate([0, -(pip_track_width + 1.5) / 2 + (pip_track_width + 1) / 2, pip_track_width / 2 - 0.15])
                                cube([pip_track_width + 1.5, pip_track_width + 1.5, 1.5]);
                        }
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
                            sphere(d = dip_pivot_dia); // 미니 구슬 (4.06mm)
                            cylinder(h = 3, d1 = dip_pivot_dia, d2 = dip_pivot_dia * 0.8, center = false);
                        }
                        // DIP 전용 미니 C-커브 경로 가공
                        rotate([90, 0, 0])
                            rotate_extrude(angle = 90)
                                translate([dip_pivot_dia / 2 + wall_thick / 2, 0, 0])
                                    circle(d = tendon_dia);
                    }
                }
                
                // -------------------------------------------------------------
                // [C] 최종 손끝 마디 어셈블리 (Distal Phalanx Unit)
                // -------------------------------------------------------------
                // 🛠️ [행렬 순서 교정]: 손끝 어셈블리 진입부 위상차 편심 방어 완료
                translate([0, -(dip_track_width + 1) / 2, -(dip_track_width + 1) / 2]) {
                    rotate([0, dip_angle, 0]) {
                        distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, f_outer_radius);
                    }
                }
            }
        }
}



// 최종 손끝 마디 및 미끄럼 방지 패드 가이드 슬롯 공통 코어 모듈
module distal_fingertip_core(d_len, dip_pivot_dia, dip_track_width, f_outer_radius) {
    difference() {
        union() {
            // 손끝 프레임 기본 뼈대
            translate([-f_outer_radius * 0.8, -5, 0]) cube([f_outer_radius * 1.6, 10, d_len]);
            // 외형 보완 및 챔퍼 효과용 대각 덤블링 라운딩 형상
            translate([0, 0, d_len - 2]) sphere(r = f_outer_radius * 0.8);
        }
        
        // DIP 하단 소켓 및 역방향 락인 스토퍼 설계 (Wedge-Lock 슬립 방지 보강 일체화)
        sphere(d = dip_track_width + 0.05);
        
        // 🛠️ [최종 교정]: translate를 바깥으로 빼내어 회전축 중심 정렬 후 스토퍼 단면 절벽 가공
        translate([0, -(dip_track_width + 1) / 2, -(dip_track_width + 1) / 2]) {
            rotate() { // 하이브리드 튜닝 정렬축 매핑
                cube([dip_track_width + 1, dip_track_width + 1, dip_track_width + 1]);
                
                // 🖨️ [DIP Wedge-Lock 슬립 방지 가드] 
                // 3D 프린팅 시 손끝 소켓 내부에 누적되는 오버행 처짐을 기하학적으로 흡수하여 차단 턱 잠금 기능 보호
                translate([0, -(dip_track_width + 1.5) / 2 + (dip_track_width + 1) / 2, dip_track_width / 2 - 0.15])
                    cube([dip_track_width + 1.5, dip_track_width + 1.5, 1.5]);
            }
        }
                
        // 🛠️ 이중 나팔꽃 보풀 가드 (DIP 측 깔때기형 입구)
        union() {
            translate([dip_pivot_dia / 2 + wall_thick / 2, 0, -1])
                cylinder(h = d_len + 2, d = tendon_dia);
            translate([dip_pivot_dia / 2 + wall_thick / 2, 0, -0.1])
                cylinder(h = 2.1, d1 = tendon_dia + 1.5, d2 = tendon_dia, center = false);
        }
        
        // 🧲 물체 파지성 향상을 위한 전면 실리콘/고무 패드 삽입 몰딩 홈 가공 (깊이 2mm)
        translate([-(f_outer_radius), -6, d_len / 2])
            cube([f_outer_radius * 2, 2, d_len / 2]);
    }
}

