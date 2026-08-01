// =================================================================
// 🌊 BioCerve-Hand: Parametric Hardware Core (v9.0 레일 통합형 관절)
// 소프트웨어 커널 v2.5 완벽 동기화 및 세로 도르래 레일 아키텍처 이식판
// =================================================================
$fn = 60; 

// [1] 하드웨어 마스터 파라메터
clearance = 0.25;       // 조립 및 회전 공차 (0.25mm)
joint_radius = 5.5;     // 독립 구형 베어링(구슬) 반지름
tendon_dia = 1.5;       // 다이니마 텐던 또는 생체 손가락 관통 코어 직경
outer_shell_r = joint_radius + 2.5; // 외벽 두께 최적화 (최소 2.0mm 방어)
box_size = outer_shell_r * 3;       // 커팅 박스 안전 크기

// [2] 관통 핀 파라메터 (좌우 커버가 가로로 꽉 쥐어 고정하는 마스터 축)
pin_dia = 2.0;          // 정중앙 가로(X축) 관통 실물 핀 지름 (2mm)

// [3] 매스터 케이블 오프셋 (인장 악력 토크 극대화를 위한 손바닥 측 고정)
wire_offset = -3.5;     // Y축 음의 방향 = 손바닥(Palm Side) 방향

// [4] 시뮬레이션 및 디스플레이 모드
// 2: 전체 외관 구조 그대로 보기 (애니메이션 가동)
// 1: 조립 단면도 투시 보기 (★ 내부 세로 레일과 핀의 교차 상태를 인스펙션하려면 1번을 켜세요)
view_mode = 2; 


// =================================================================
// 🦴 [파트 1] 위쪽 프레임 (Proximal Segment - 좌측 커버 쉘)
// =================================================================
module proximal_segment() {
    difference() {
        union() {
            // 메인 위쪽 기둥 골격
            translate([0, 0, 15/2 + joint_radius]) cube([12, 12, 15], center=true);
            
            // [좌측 감싸기 쉘] X=0 기준 왼쪽(X < 0) 영역만 남겨 구슬을 좌측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([box_size/2 - 0.4 + clearance/2, 0, 0]) cube([box_size, box_size, box_size], center=true); 
            }
            
            // ★ [스토퍼 A] 수동 기계적 락인(Wedge-Lock) 후방 턱
            translate([-12/4, outer_shell_r - 1.5, 0]) 
                cube([12/2 - clearance/2, 3, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀
        rotate([0, 90, 0]) cylinder(h=40, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽)에서 구슬 세로 레일 초입으로 내려오는 수직 와이어 가이드 홀
        translate([0, wire_offset, 15/2 + joint_radius]) cylinder(h=25, r=tendon_dia/2, center=true);
        
        sphere(r=joint_radius + clearance);         // 중심 구슬 안착 소켓 홈
        
        // 오른쪽(X > 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([box_size/2 - 0.4 + clearance/2, 0, 0]) cube([box_size, box_size, box_size], center=true);
        }
        
        // 앞쪽 하단 구동 간섭 방지 오픈 영역
        translate([0, -joint_radius-2, -joint_radius-1]) cube([20, 12, 12], center=true);
    }
}


// =================================================================
// 🎡 [교정 파트 2] 세로 도르래 레일 핵심 코어 구슬 (Central Pivot Sphere)
// =================================================================
module independent_ball_bearing() {
    difference() {
        sphere(r=joint_radius); // 기본 무결점 구슬 코어
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀 (좌우 2mm 관통)
        rotate([0, 90, 0]) 
            cylinder(h=joint_radius * 3, r=pin_dia/2, center=true);
        
        // 🎡 [세로 레일 홈 최종 교정] 
        // rotate_extrude의 기본 Z축 중심을 Y축 기준으로 90도 회전(또는 X축 회전 적용)하여
        // 손가락이 0~90도로 접히는 궤적(세로 평면)과 완전히 일치하도록 둥글게 깎아냅니다.
        rotate([0, 90, 0]) { 
            rotate_extrude() {
                translate([joint_radius, 0, 0]) 
                    circle(r=tendon_dia/2 + clearance); // 와이어 굵기 + 여유 공차
            }
        }
    }
}



// =================================================================
// 🦴 [파트 3] 아래쪽 프레임 (Distal Segment - 우측 커버 쉘)
// =================================================================
module distal_segment() {
    difference() {
        union() {
            // 메인 아래쪽 기둥 골격
            translate([0, 0, -(15/2 + joint_radius)]) cube([12, 12, 15], center=true);
            
            // [우측 감싸기 쉘] X=0 기준 오른쪽(X > 0) 영역만 남겨 구슬을 우측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([-(box_size/2 + clearance/2), 0, 0]) cube([box_size, box_size, box_size], center=true); 
            }
            
            // ★ [스토퍼 B] 수동 기계적 락인(Wedge-Lock) 후방 턱
            translate([12/4, outer_shell_r - 1.5, 0]) 
                cube([12/2 - clearance/2, 3, joint_radius * 2], center=true);
        }
        
        // 🔒 [절대 고정] 가로 정중앙 X축 관통 핀 홀
        rotate([0, 90, 0]) cylinder(h=40, r=pin_dia/2, center=true);
        
        // 🛠️ [소프트웨어 동기화] 손바닥(앞쪽) 하단 기둥으로 탈출하는 수직 와이어 가이드 홀
        translate([0, wire_offset, -(15/2 + joint_radius)]) cylinder(h=25, r=tendon_dia/2, center=true);
        
        sphere(r=joint_radius + clearance + 0.15);         // 중심 구슬 안착 소켓 홈 +0.15 여유
        
        // 왼쪽(X < 0) 내부 홈 비우기 (중앙 구슬이 들어갈 공간 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([-(box_size/2 + clearance/2), 0, 0]) cube([box_size, box_size, box_size], center=true);
        }
        
        // 🛠️ [레일 동기화 챔퍼] 구슬의 세로 레일을 타고 내려온 와이어가 0도~90도 폴딩 시 
        // 떡지거나 걸리지 않고 손바닥 탈출구(`wire_offset`)로 미끄러져 들어오도록 유도하는 부채꼴 슬롯 컷
        rotate([0, 0, 0]) {
            translate([0, wire_offset, -joint_radius/2])
                cylinder(h=joint_radius * 1.5, r1=tendon_dia/2 + 1.2, r2=tendon_dia/2, center=true);
        }
        
        // 상단 전면부 회전 간섭 제거용 경사 컷
        translate([0, -joint_radius-2, joint_radius]) rotate([-20,0,0]) cube([20, 12, 12], center=true);
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
        translate([box_size/2, 0, 0]) cube([box_size, box_size, box_size], center=true); 
    }
} else {
    // 예외/디버그 모드: 각 파트를 분해하여 원점 정렬 상태 인스펙션
    color("LightBlue") translate([-15, 0, 0]) proximal_segment(); 
    color("Lime") translate([0, 0, joint_radius]) independent_ball_bearing(); 
    color("Tomato") translate([15, 0, 15/2 + joint_radius*2]) rotate([0, 180, 0]) distal_segment(); 
}
