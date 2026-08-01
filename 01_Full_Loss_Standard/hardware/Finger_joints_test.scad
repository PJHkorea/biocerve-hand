// =================================================================
// 🌊 BioCerve-Hand: Parametric Hardware Core (v9.0 레일 통합형 관절)
// =================================================================
$fn = 60; 

// [1] 하드웨어 마스터 파라메터
clearance = 0.25;       // 조립 및 회전 공차 (0.25mm)
joint_radius = 5.5;     // 독립 구형 베어링(구슬) 반지름
tendon_dia = 1.5;       // 다이니마 텐던 또는 생체 손가락 관통 코어 직경
outer_shell_r = joint_radius + 2.5; // 외벽 두께 최적화
box_size = outer_shell_r * 3;       // 커팅 박스 안전 크기

// 🌟 [새로 추가된 손가락 뼈대 치수 변수]
finger_width = 12;      // 손가락 마디의 가로/세로 두께 (기존 12)
bone_length = 15;       // 손가락 뼈대 기둥의 수직 길이 (기존 15)

// [2] 관통 핀 파라메터
pin_dia = 2.0;          

// [3] 매스터 케이블 오프셋
wire_offset = -3.5;     

// [4] 시뮬레이션 및 디스플레이 모드
view_mode = 2;


// =================================================================
// 🌊 BioCerve-Hand: 파라메터 확장 (파트 1용 신규 변수 추가)
// =================================================================
// 기존 마스터 파라메터에 아래 3가지 주요 외관 변수를 정의합니다.
finger_w       = 12;    // 손가락 마디의 가로/세로 두께 (기존 12)
bone_h         = 15;    // 기둥(뼈대)의 수직 길이 (기존 15)
stopper_thick  = 3;     // 스토퍼 후방 턱의 Y축 두께 (기존 3)

// 내부 연산 안정성을 위한 자동 계산 서브 변수
side_margin    = 1.5;   // 좌우 쉘 커팅을 위한 마스터 오프셋 마진 (기존 1.5)
inner_clear_x  = 0.4;   // 내부 홈 비우기용 X축 미세 마진 (기존 0.4)

// =================================================================
// 🦴 [파트 1] 위쪽 프레임 (Proximal Segment - 좌측 커버 쉘)
// =================================================================
module proximal_segment() {
    difference() {
        union() {
            // 🟥 메인 위쪽 기둥 골격 (12, 15를 변수화)
            translate([0, 0, bone_h/2 + joint_radius]) 
                cube([finger_w, finger_w, bone_h], center=true);
            
            // 🟢 [좌측 감싸기 쉘] X=0 기준 왼쪽(X < 0) 영역만 남겨 구슬을 좌측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([box_size/2 - side_margin + clearance/2, 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
            }
            
            // 📐 [스토퍼 A] 수동 기계적 락인(Wedge-Lock) 후방 턱 (치수 연동)
            translate([-finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀 (길이는 box_size 활용 안전 마진 확보)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽)에서 구슬 세로 레일 초입으로 내려오는 수직 와이어 가이드 홀
        translate([0, wire_offset, bone_h/2 + joint_radius]) 
            cylinder(h=bone_h * 2, r=tendon_dia/2, center=true);
        
        sphere(r=joint_radius + clearance);         // 중심 구슬 안착 소켓 홈
        
        // 🔵 오른쪽(X > 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([box_size/2 - inner_clear_x + clearance/2, 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }
        
        // ⚠️ 앞쪽 하단 구동 간섭 방지 오픈 영역 (손가락 두께 변수에 비례하여 자동 조절)
        translate([0, -joint_radius - 2, -joint_radius - 1]) 
            cube([finger_w * 2, finger_w, finger_w], center=true);
    }
}



// =================================================================
// 🎡 [교정 파트 2] 세로 도르래 레일 핵심 코어 구슬 (Central Pivot Sphere)
// =================================================================
module independent_ball_bearing() {
    // 내부 연산을 위한 서브 파라메터
    // 와이어가 완전히 구슬 안쪽으로 안전하게 파고들도록 궤적 반지름을 정의합니다.
    rail_track_r = joint_radius; 
    rail_groove_r = tendon_dia / 2 + clearance; // 와이어 굵기 + 여유 공차

    difference() {
        // 🟢 기본 무결점 구슬 코어
        sphere(r=joint_radius); 
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀
        // 관통력 확보를 위해 길이를 확실하게 (box_size 활용) 늘려줍니다.
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🎡 [세로 레일 홈 최종 교정] 
        // 2D 원을 돌려 도넛을 만든 후, 이를 회전시켜 세로 구동 궤적과 일치시킵니다.
        rotate([0, 90, 0]) { 
            rotate_extrude() {
                // 회전축에서 rail_track_r 만큼 떨어진 곳에 홈을 파낼 원을 배치합니다.
                // 팁: 실이 완전히 안착하게 하려면 rail_track_r에서 고정 상수 대신 미세 조정을 할 수도 있습니다.
                translate([rail_track_r, 0, 0]) 
                    circle(r=rail_groove_r); 
            }
        }
    }
}



// =================================================================
// 🦴 [파트 3] 아래쪽 프레임 (Distal Segment - 우측 커버 쉘)
// =================================================================
module distal_segment() {
    // 내부 연산을 위한 서브 파라메터 (부채꼴 슬롯 및 간섭 방지 컷용 변수)
    chamfer_h      = joint_radius * 1.5 - 1; // 와이어 유도 챔퍼의 수직 높이
    chamfer_r1     = tendon_dia/2 + 1.2;     // 챔퍼 바닥 진입부 반지름 (가이드 넓이)
    chamfer_r2     = tendon_dia/2;           // 챔퍼 상단 탈출부 반지름 (와이어 딱 맞는 크기)
    distal_clear_x = 0.0;                    // 왼쪽 내부 홈 비우기용 X축 오프셋 (기존 0 적용)

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
            }
            
            // 📐 [스토퍼 B] 수동 기계적 락인(Wedge-Lock) 후방 턱 (대칭 변수 연동)
            translate([finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽) 하단 기둥으로 탈출하는 수직 와이어 가이드 홀
        translate([0, wire_offset, -(bone_h/2 + joint_radius)]) 
            cylinder(h=bone_h * 2, r=tendon_dia/2, center=true);
        
        // 중심 구슬 안착 소켓 홈 (하단 기둥은 조립성 및 구동 유연성을 위해 +0.15 여유 마진 유지)
        sphere(r=joint_radius + clearance + 0.15);         
        
        // 🔵 왼쪽(X < 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([-(box_size/2 + distal_clear_x + clearance/2), 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }
        
        // 🎡 [레일 동기화 챔퍼] 0도~90도 폴딩 시 와이어가 걸리지 않게 유도하는 부채꼴 슬롯 컷
        rotate([0, 0, 0]) {
            translate([0, wire_offset, -joint_radius/2])
                cylinder(h=chamfer_h, r1=chamfer_r1, r2=chamfer_r2, center=true);
        }
        
        // ⚠️ 상단 전면부 회전 간섭 제거용 경사 컷 (손가락 두께 변수에 맞춰 자동 칼날 크기 조절)
        translate([0, -joint_radius - 2, joint_radius]) 
            rotate([-20, 0, 0]) 
                cube([finger_w * 2, finger_w, finger_w], center=true);
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
