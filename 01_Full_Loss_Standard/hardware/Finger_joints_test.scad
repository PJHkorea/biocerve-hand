// =================================================================
// 🌊 BioCerve-Hand: Parametric Hardware Core (v9.1 통합 파라메터 마스터)
// =================================================================
$fn = 60; 

// 🎯 [1] 마디 및 뼈대 치수 (기하학 핵심)
finger_w       = 12;    // 손가락 마디의 가로/세로 두께 (기존 12)
bone_h         = 15;    // 손가락 뼈대 기둥의 수직 길이 (기존 15)
joint_radius   = 5.5;   // 내부 핵심 구슬(중앙 피벗 구체) 반지름 (기존 5.5)

// 📐 [2] 하우징 및 스토퍼 파라메터
outer_shell_r  = joint_radius + 2.5; // 외벽 껍데기 반지름 (최소 2.0mm 방어벽 자동 연동)
stopper_thick  = 3;     // 기계적 락인 후방 스토퍼 턱의 Y축 두께 (기존 3)

// ⚙️ [3] 조립 공차 및 마진 (3D 프린트 출력/회전용)
clearance      = 0.25;  // 기본 조립 및 가동 유격 공차 (0.25mm)
side_margin    = 1.5;   // 좌우 커버 쉘 분할 커팅용 오프셋 마진 (기존 1.5)
inner_clear_x  = 0.4;   // 파트 1 내부 홈 비우기용 X축 미세 마진 (기존 0.4)
box_size       = outer_shell_r * 3; // 연산용 칼날(커팅 박스) 안전 크기 자동 계산

// 🔒 [4] 관통 핀 및 인장선(하드웨어 스펙 연동)
pin_dia        = 2.0;   // 정중앙 가로(X축)를 관통하는 실물 고정 핀 지름 (2mm)
tendon_dia     = 1.5;   // 구동용 다이니마 텐던(실) 관통 코어 직경 (1.5mm)
wire_offset    = -3.5;  // 토크 극대화를 위한 와이어 가이드 Y축 편향 위치 (손바닥 방향)

// 🎬 [5] 시뮬레이션 및 디스플레이 모드
// 2: 정상 가동 및 애니메이션 모드 
// 1: 이중 단면 인스펙션 투시 모드 
// 3: 조립 해제 및 파트별 분해 검제 모드
view_mode = 2 ;


// =================================================================
// 🦴 [파트 1] 위쪽 프레임 (Proximal Segment - 좌측 커버 쉘) 라이트블루색
// =================================================================
module proximal_segment() {
    // 🛞 [실물 윤활 고정 핀/빨대 사양 파라메터 지정]
    roller_pin_d = 1.5;  // 구리스+빨대를 씌운 실물 가로 핀 지름 (1.5mm)

    difference() {
        union() {
            // 🟥 메인 위쪽 기둥 골격 (finger_w, bone_h 변수 연동)
            translate([0, 0, bone_h/2 + joint_radius]) 
                cube([finger_w, finger_w, bone_h], center=true);
            
            // 🟢 [좌측 감싸기 쉘] X=0 기준 왼쪽(X < 0) 영역만 남겨 구슬을 좌측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([box_size/2 - side_margin + clearance/2, 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
                
                // =================================================================
                // 🦴 [파트 1 수정] 위쪽 프레임 하단 쉘 변형 가공
                // =================================================================
                // [신규 추가: 전방 스커트 쉘 간섭 제거 경사 컷]
                // 신 빨간 네모(손바닥 쪽 하단 쉘)를 과감하게 경사로 쳐내어 
                // 하부 마디가 회전할 때 간섭도 없이 완벽하게 비껴가도록 궤적을 개방
                translate([0, -outer_shell_r, 0]) // Y축 앞쪽(손바닥 방향) 모서리로 이동
                    rotate([0, 30, 50])            // 3D 드로잉 지시선 각도와 일치하는 0, 30, 50도 경사 컷
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }
            
            // 📐 [스토퍼 A] 수동 기계적 락인(Wedge-Lock) 후방 턱 (치수 연동)
            translate([-finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 메인 핀 홀 (가로 방향으로 확실하게 관통)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽)에서 구슬 세로 레일 초입으로 내려오는 수직 와이어 가이드 홀
        translate([0, wire_offset, bone_h/2 + joint_radius]) 
            cylinder(h=bone_h * 2, r=tendon_dia/2, center=true);
        
        // ✨ [신규 추가: 상부 단선 방지용 가로 핀 홀]
        // 🎯 [정밀 대칭 매립]: 토마토색 마디의 검은 구멍 좌표(-4.5, -joint_radius - 1)와 거울처럼 완벽한 대칭을 이룹니다.
        // 세로 터널 중심과 앞벽 사이의 알짜배기 기둥 속 살집에 콤팩트하게 박아 외벽을 완벽히 보호합니다.
        proximal_pin_y = wire_offset - 1.0 ;
        proximal_pin_z = joint_radius + 0.8; // 하부 마디(-1.0)와 정반대인 상부(+1.0) 대칭 매핑!
        
        translate([0, proximal_pin_y, proximal_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
        
        sphere(r=joint_radius + clearance);         // 중심 구슬 안착 소켓 홈
        
        // 🔵 오른쪽(X > 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([box_size/2 - inner_clear_x + clearance/2, 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }
        
    
    }
}



// =================================================================
// 🎡 [교정 파트 2] 세로 도르래 레일 핵심 코어 구슬 (Central Pivot Sphere)
// =================================================================
module independent_ball_bearing() {
    // 내부 연산을 위한 서브 파라메터
    // 와이어가 완전히 구슬 안쪽으로 안전하게 파고들도록 궤적 반지름을 정의합니다.
    rail_track_r  = joint_radius; 
    rail_groove_r = tendon_dia / 2 + clearance; // 와이어 굵기 + 여유 공차

    difference() {
        // 🟢 기본 무결점 구슬 코어 (joint_radius 마스터 변수 연동)
        sphere(r=joint_radius); 
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀
        // 관통력 확보를 위해 길이를 통합 규격(box_size * 2)으로 관통합니다.
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🎡 [세로 레일 홈 최종 교정] 
        // 2D 원을 돌려 도넛을 만든 후, 이를 회전시켜 세로 구동 궤적과 일치시킵니다.
        rotate([0, 90, 0]) { 
            rotate_extrude() {
                // 회전축에서 rail_track_r 만큼 떨어진 곳에 홈을 파낼 원을 배치합니다.
                translate([rail_track_r, 0, 0]) 
                    circle(r=rail_groove_r); 
            }
        }
    }
}



// =================================================================
// 🦴 [파트 3] 아래쪽 프레임 (Distal Segment - 우측 커버 쉘) 토마토색
// =================================================================
module distal_segment() {
    // 🪚 [상수 청소 완료] 파트 1에 존재하지 않는 쓰이지 않는 chamfer 계열 변수 3줄 완벽 제거!
    distal_clear_x = 0.0;                    // 왼쪽 내부 홈 비우기용 X축 오프셋 (기존 0 적용)

    // 🛞 [실물 핀 스펙 마스터 파라메터] 파트 1의 roller_pin_d 규격과 정확히 일치시킴
    roller_pin_d = 1.5;  // 가로 고정 핀 지름 (1.5mm)



    difference() {
        union() {
            // 🟥 메인 아래쪽 기둥 골격 (finger_w, bone_h 변수 연동)
            translate([0, 0, -(bone_h/2 + joint_radius)]) 
                cube([finger_w, finger_w, bone_h], center=true);
            
            // 🟢 [우측 감싸기 쉘] X=0 기준 오른쪽(X > 0) 영역만 남겨 구슬을 우측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([-(box_size/2 - side_margin + clearance/2), 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
                
                // =================================================================
                // 🦴 [완벽 대칭 패치] 아래쪽 프레임 하단 쉘 변형 가공 (파트 1 기준 일치)
                // =================================================================
                // 파트 1 기준 코드의 50도 경사 컷 메커니즘을 100% 동일하게 복사 적용했습니다.
                // 하단 궤적의 깎임 방향에 맞춰 각도 부호만 반대(-50)로 주어 완벽한 대칭형 반원을 구현합니다.
                translate([0, -outer_shell_r, 0]) 
                    rotate([0, 30, -50])            
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }
            
            // 📐 [스토퍼 B] 수동 기계적 락인(Wedge-Lock) 후방 턱 (대칭 변수 연동)
            translate([finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 메인 핀 홀 (파트 1과 완벽 일치)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽) 하단 기둥으로 탈출하는 메인 수직 와이어 가이드 홀
        translate([0, wire_offset, -(bone_h/2 + joint_radius)]) 
            cylinder(h=bone_h * 2, r=tendon_dia/2, center=true);
        
        // 🪚 [상수 청소 완료] 음수 유격을 만들던 롤러 주머니 룸(cube) 연산 코드 완전 제거!

        // ✨ [하부 단선 방지용 가로 핀 홀 - 불량 상수 교정 완료]
        // 🎯 [정밀 대칭 매립]: 파트 1 기준 코드의 수식(wire_offset - 1.0)과 거울처럼 완벽한 동기화!
        // 기존의 고정 상수 '-4.5'와 '-1'을 지우고, 파트 1과 유기적으로 대칭 구동되도록 완전히 수정했습니다.
        target_pin_y = wire_offset - 1.0; 
        target_pin_z = -joint_radius - 0.8; // 파트 1(+0.8)과 정반대인 하부(-0.8) 대칭 매핑!

        translate([0, target_pin_y, target_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
        
        // 중심 구슬 안착 소켓 홈 (하단 기둥은 조립성 및 구동 유연성을 위해 +0.15 여유 마진 유지)
        sphere(r=joint_radius + clearance + 0.15);         
        
        // 🔵 왼쪽(X < 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([-(box_size/2 + clearance/2), 0, 0]) // 🪚 유령 변수 distal_clear_x 제거 후 완벽 정렬
                cube([box_size, box_size, box_size], center=true);
        }
    }
}



// =================================================================
// 🎬 [최종 제어 파이프라인 및 조립 인터페이스]
// =================================================================
module final_assembled_joint() {
    current_angle = -90 * $t; // 오픈스캐드 자체 애니메이션 대응 (0도 ~ -90도 회전 실시간 구동)

    color("LightBlue") proximal_segment();
    color("Lime") independent_ball_bearing();

    // 세로 레일을 타고 부드럽게 연동되어 회전하는 아래쪽 마디
    rotate([current_angle, 0, 0])
        color("Tomato") distal_segment();
}

// --- 인스펙션 연산 및 이중 모드 시각화 스위칭 ---
if (view_mode == 2) {
    final_assembled_joint(); // 2번: 부품이 완벽히 맞물려 구동되는 실물 모드
} else if (view_mode == 1) {
    // 1번: 내부 세로 레일 홈과 가로 핀이 칼같이 90도로 비껴가는지 단면 검제 모드
    difference() {
        final_assembled_joint();
        // 절반을 칼같이 자르기 위해 box_size 기반 정렬 유지
        translate([box_size/2, 0, 0]) cube([box_size, box_size, box_size], center=true); 
    }
} else {
    // 🛠️ 예외/디버그 모드 (view_mode = 3): 각 파트를 분해하여 원점 정렬 상태 인스펙션
    // 손가락 두께(finger_w)와 기둥 길이(bone_h)에 비례하여 자동으로 멀어지도록 수식화했습니다.
    explode_distance = finger_w * 1.5; // 부품이 양옆으로 벌어질 안전 거리

    // [좌측] 위쪽 프레임 분해 배치
    color("LightBlue") 
        translate([-explode_distance, 0, 0]) proximal_segment(); 
    
    // [중앙] 제어 구슬 코어 배치
    color("Lime") 
        translate([0, 0, joint_radius]) independent_ball_bearing(); 
    
    // [우측] 아래쪽 프레임 분해 배치 (bone_h와 joint_radius 수식 연동으로 겹침 원천 차단)
    color("Tomato") 
        translate([explode_distance, 0, bone_h/2 + joint_radius*2]) 
            rotate([0, 180, 0]) distal_segment(); 
}
