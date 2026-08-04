// =================================================================
// 🌊 BioCerve-Hand: Parametric Hardware Core (v9.1 통합 파라메터 마스터)
// =================================================================
$fn = 60; 

// 🎯 마디 및 뼈대 치수 (기하학 핵심)
finger_w = 15; // [마스터 변수] 손가락 두께 기준값 고정

proximal_bone_h   = finger_w * 1.8; // 계산값: 21.6mm
middle_bone_h     = proximal_bone_h * 0.7; // 계산값: 15.12mm
distal_bone_h     = proximal_bone_h * 0.5; // 계산값: 10.8mm
joint_radius      = finger_w * (5.5 / 12); // 계산값: 6.875mm
metacarpal_bone_h = finger_w * 2.5; // 계산값: 37.5mm

// =================================================================
// 🆕 🛠️ [가이드 타워 및 판스프링 관통 규격 최종 매핑]
// =================================================================

spring_slot_w     = finger_w * 0.6;     // 외부 가이드 타워 기둥을 관통할 슬롯 너비 (9mm)
spring_slot_h     = 0.8;                // 페트병 판스프링이 주행할 슬롯 틈새 두께 (0.8mm)

guide_tower_w     = finger_w - (finger_w*0.2); // 타워 좌우 폭
guide_tower_thick = finger_w / 3 ;                // 판스프링 장력을 버텨낼 타워 전후(Y축) 두께 현 기준 5미리
guide_tower_h     = joint_radius * 3.2; // 순정 후방 스토퍼 위로 우뚝 솟구칠 타워 높이 스펙




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
// 🦴 [손등뼈 최종 확정본] metacarpal_bone - 세로축 수직 관통 슬롯 터널 완성
// =================================================================
module metacarpal_bone() {
    roller_pin_d = 1.5;
    bushing_dia  = 3.0; 
    bushing_depth = 5.0; 

    difference() {
        // [1단계: 겉껍질 메인 골격 형성 - 순정 네모 기둥 & 가이드 블록 유니온]
        union() {
            // 1. 🟥 순정 네모 손등뼈 뼈대 기둥
            translate([0, 0, metacarpal_bone_h/2 + joint_radius])
                cube([finger_w, finger_w, metacarpal_bone_h], center=true);
            
            // 2. 🟢 하단 소켓 쉘 
            difference() {
                sphere(r=outer_shell_r); 
                translate([-(box_size/2 - side_margin + clearance/2), 0, 0])
                    cube([box_size, box_size, box_size], center=true);
                translate([0, -outer_shell_r, 0])
                    rotate([0, 65, -50])
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }

            // 📐 [순정 스토퍼 사수] 반구 뒤편 과신전 방지 턱 
            translate([finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);

            // 🎯 [순정 가이드 블록 안착 스펙 완벽 사수] 
            translate([0, finger_w/2 + (guide_tower_thick/2), joint_radius + (metacarpal_bone_h * 0.5)])
                cube([guide_tower_w, guide_tower_thick, guide_tower_h], center=true);
        }
        
        // [2단계: 내부 공간 및 하단 관통 소켓/핀홀 최종 차집합 파내기]
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
            
        translate([0, wire_offset, metacarpal_bone_h/2 + joint_radius]) 
            cylinder(h=metacarpal_bone_h * 2, r=tendon_dia/2, center=true);
        
        top_face_z = metacarpal_bone_h + joint_radius;
        translate([0, wire_offset, top_face_z - bushing_depth/2 + 0.1]) cylinder(h=bushing_depth, r=bushing_dia/2, center=true);
        translate([0, wire_offset, top_face_z - 0.5]) cylinder(h=1.5, r1=tendon_dia/2, r2=bushing_dia/2 + 0.5, center=true);
            
        sphere(r=joint_radius + clearance + 0.15);
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([-(box_size/2 + clearance/2), 0, 0]) cube([box_size, box_size, box_size], center=true);
        }
        
        metacarpal_pin_y = wire_offset - 1.0;
        metacarpal_pin_z = joint_radius + 1.0;  //단선 방지 구멍 위치는 1.0 내외로 체크후 수정
        translate([0, metacarpal_pin_y, metacarpal_pin_z]) 
            rotate([0, 90, 0]) 
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);

        // =================================================================
        // 🆕 🕳️ [기하학 보정: 세로축 수직 관통 판스프링 터널 슬롯]
        // =================================================================
        // 🎯 [위상 반전 패치]: 앞뒤로 깎던 칼날 큐브를 Z축 세로 방향으로 길게 세워 배치합니다!
        // Y축 두께는 판스프링 두께 스펙인 `spring_slot_h`로 제한하여 기둥 본체를 완벽히 보호하고,
        // Z축 높이를 길게 늘려(`guide_tower_h + 10`) 가이드 블록 내부를 위아래로 시원하게 관통시킵니다.
        mcp_tunnel_y = finger_w/2 + (guide_tower_thick/2);
        mcp_tunnel_z = joint_radius + (metacarpal_bone_h * 0.5);
        
        translate([0, mcp_tunnel_y, mcp_tunnel_z])
            cube([spring_slot_w + clearance, spring_slot_h + clearance, guide_tower_h + 10], center=true);
    }
}





// =================================================================
// 🦴 [파트 1 완벽 개량] 위쪽 프레임 (Proximal Segment) - 상/하단 이중 소켓 쉘 통합
// =================================================================
module proximal_segment() {
    roller_pin_d = 1.5;  // 구리스+빨대를 씌운 실물 가로 핀 지름 (1.5mm)

    difference() {
        // [1단계: 겉껍질 메인 골격 형성 - 상/하단 유니온 결합]
        union() {
            // 🟥 메인 위쪽 기둥 골격 (finger_w, proximal_bone_h 변수 연동)
            translate([0, 0, proximal_bone_h/2 + joint_radius]) 
                cube([finger_w, finger_w, proximal_bone_h], center=true);
            
            // 🟢 [하단부: 원래 설계] X=0 기준 왼쪽(X < 0) 영역 구슬 고정 쉘
            difference() {
                sphere(r=outer_shell_r);
                translate([box_size/2 - side_margin + clearance/2, 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
                
                // [하단 간섭 제거 경사 컷]
                translate([0, -outer_shell_r, 0]) 
                    rotate([0, 30, 50])            
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }
            
            // 📐 [스토퍼 A] 하단 수동 기계적 락인(Wedge-Lock) 후방 턱
            translate([-finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);

            // =================================================================
            // 🆕 🟢 [상단부 추가]: 신규 빨간 박스 영역 MCP 관절용 상부 좌측 감싸기 쉘
            // =================================================================
            // 기둥 맨 윗면 높이(proximal_bone_h + joint_radius)로 정확히 이동하여 
            // 하단 쉘 구조와 일란성 쌍둥이처럼 완벽한 대칭을 형성합니다.
            translate([0, 0, proximal_bone_h + joint_radius * 2]) {
                difference() {
                    sphere(r=outer_shell_r);
                    // 좌측 쉘 사양 유지 (오른쪽 절단)
                    translate([box_size/2 - side_margin + clearance/2, 0, 0]) 
                        cube([box_size, box_size, box_size], center=true); 
                    
                    // [상단 간섭 제거 역방향 경사 컷] 회전 시 상부 손등뼈와의 충돌 방지
                    translate([0, -outer_shell_r, 0]) 
                        rotate([0, -30, 50]) // 회전축 간섭 회피용 대칭 각도 가공           
                            cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
                }
            }

                       // 📐 [스토퍼 E] 상부 MCP 관절 수동 기계적 락인 후방 턱
            translate([-finger_w/4, outer_shell_r - side_margin, proximal_bone_h + joint_radius * 2]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);

            // =================================================================
            // 🆕 🎯 [1마디 가이드 블록 뼈대 안착 - 무결점 솟아오름 구조]
            // =================================================================
            // 손등뼈 모듈과 완벽하게 1자 동축 정렬선을 형성하도록 배치합니다.
            // 상하단 반구형 소켓 쉘 두께(outer_shell_r)를 영구 보호하기 위해 
            // 안전 마진(safe_zone_l) 수식 범위 내에만 타워가 솟아오르도록 방어합니다.
            safe_zone_l = proximal_bone_h - (outer_shell_r * 2); 
            tower_l      = safe_zone_l * 0.95; // 안전 지대의 95% 스케일로 기둥 길이 제어
            
            translate([0, finger_w/2 + (guide_tower_thick/2), proximal_bone_h/2 + joint_radius])
                cube([guide_tower_w, guide_tower_thick, tower_l], center=true);
        }

        
        // [2단계: 내부 공간 및 상/하단 관통 소켓 통로 최종 파내기]
        
        // 🔒 [하단 절대 고정] 가로 정중앙 X축 관통 메인 핀 홀 (Z=0)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ 하단 와이어 가이드 홀
        translate([0, wire_offset, proximal_bone_h/2 + joint_radius]) 
            cylinder(h=proximal_bone_h * 2, r=tendon_dia/2, center=true);
        
        // ✨ 하단 단선 방지용 가로 핀 홀
        proximal_pin_y = wire_offset - 1.0;
        proximal_pin_z = joint_radius + 0.8; 
        translate([0, proximal_pin_y, proximal_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
        
        // 🟢 하단 중심 구슬 안착 소켓 홈
        sphere(r=joint_radius + clearance);         
        
        // 🔵 하단 오른쪽 내부 홈 비우기 (중앙 구슬 공간)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([box_size/2 - inner_clear_x + clearance/2, 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }

        // =================================================================
        // 🕳️ 🔄 [신규 추가]: 상단 MCP 관절 안착 구형 홈 및 통로 연산
        // =================================================================
        // 🟢 상단 중심 구슬 안착 소켓 밥그릇 파내기
        translate([0, 0, proximal_bone_h + joint_radius * 2])
            sphere(r=joint_radius + clearance);

        // 🔵 상단 오른쪽 내부 홈 비우기 (기하학 무결성 100% 동기화)
        translate([0, 0, proximal_bone_h + joint_radius * 2]) {
            intersection() {
                sphere(r=outer_shell_r + clearance);
                translate([box_size/2 - inner_clear_x + clearance/2, 0, 0]) 
                    cube([box_size, box_size, box_size], center=true);
            }
        }

           // [상단 대응: 정밀 페트병 판스프링 진입 패스 연산 코어 가이드용 임시 마진]
        calculated_top_pin_z = (proximal_bone_h + joint_radius) - 1.2;
        translate([0, proximal_pin_y, calculated_top_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);

        // =================================================================
        // 🆕 🕳️ [기하학 매핑 완료: 1마디 세로축 수직 관통 판스프링 터널 슬롯]
        // =================================================================
        // 🎯 [위상 동기화]: 칼날 큐브를 Z축 세로 방향으로 길게 세워 배치합니다!
        // Y축 두께는 판스프링 두께 스펙인 `spring_slot_h + clearance` (0.8mm+공차)로 제한하여
        // 1마디 순정 네모 본체를 완벽하게 보호하고 오직 등면 가이드 블록만 수직으로 터널링합니다.
        // 고도 마진은 상하단 쉘 파손을 완벽히 차단했던 안전 뼈대 길이(`tower_l`)를 그대로 공유합니다.
        mcp_tunnel_y = finger_w/2 + (guide_tower_thick/2);
        mcp_tunnel_z = proximal_bone_h/2 + joint_radius;
        
        safe_zone_l  = proximal_bone_h - (outer_shell_r * 2); 
        tower_l       = safe_zone_l * 0.95; // 쉘 충돌 방지용 검증된 타워 고도 스펙 공유

        translate([0, mcp_tunnel_y, mcp_tunnel_z])
            cube([spring_slot_w + clearance, spring_slot_h + clearance, tower_l + 0.2], center=true);
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
// 🦴 [파트 3] ( middle_segment ) 토마토색 엄지손가락 2번째마디를 편의상 미들로 처리
// =================================================================
module middle_segment() {
   
    // 🛞 [실물 핀 스펙 마스터 파라메터] 파트 1의 roller_pin_d 규격과 정확히 일치시킴
    roller_pin_d = 1.5;  // 가로 고정 핀 지름 (1.5mm)



    difference() {
        union() {
            // 🟥 메인 아래쪽 기둥 골격 (finger_w, middle_bone_h 변수 연동)
            translate([0, 0, -(middle_bone_h/2 + joint_radius)]) 
                cube([finger_w, finger_w, middle_bone_h], center=true);
            
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
        translate([0, wire_offset, -(middle_bone_h/2 + joint_radius)]) 
            cylinder(h=middle_bone_h * 2, r=tendon_dia/2, center=true);
        
        // 🪚 [상수 청소 완료] 음수 유격을 만들던 롤러 주머니 룸(cube) 연산 코드 완전 제거!

        // ✨ [하부 단선 방지용 가로 핀 홀 - 불량 상수 교정 완료]
        // 🎯 [정밀 대칭 매립]: 파트 1 기준 코드의 수식(wire_offset - 1.0)과 거울처럼 완벽한 동기화!
        // 기존의 고정 상수 '-4.5'와 '-1'을 지우고, 파트 1과 유기적으로 대칭 구동되도록 완전히 수정했습니다.
        target_pin_y = wire_offset - 1.0; 
        target_pin_z = -joint_radius - 1.0 ; // 파트 1(+0.8)과 정반대인 하부(-1.0) 대칭 매핑! 2번째마디 구멍으로 들어가는 케이블이 턱에 거리나 체크하고 구멍 조금씩 수정하기 -0.8정도까지

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
// 🎬 [최종 제어 파이프라인 - 엄지손가락 전용 2중 관절 매커니즘 완결본]
// =================================================================
module final_assembled_joint() {
    // 오픈스캐드 자체 애니메이션 대응 (0도 ~ -90도 회전 실시간 구동)
    current_angle = -90 * $t; 

    // 1. [상부 관절 영역] 1번째 마디(라이트블루) & 1번째 구슬(연두색) - 월드 원점 고정
    color("LightBlue") proximal_segment();
    color("Lime") independent_ball_bearing(); // 🟢 1번째 상단 관절 구슬

       // =================================================================
    // 🎯 [시뮬레이션 축 교정]: 다른 파트들과 완벽하게 Y축 정렬선을 공유하는 동축 정렬
    // =================================================================
    mcp_align_x = 0;
    mcp_align_y = 0; 
    mcp_align_z = proximal_bone_h + joint_radius * 2;

    translate([mcp_align_x, mcp_align_y, mcp_align_z]) {
        // 🎯 [워닝 제로 가드]: 비어있던 rotate 괄호 안에 [0, 0, 0]을 명시하여 콘솔창 경고를 소멸시킵니다.
        rotate([0, 0, 0]) { 
            rotate([current_angle * -0.3, 0, 0]) {
                color("LightGray") metacarpal_bone();
                color("Lime") independent_ball_bearing(); 
            }
        }
    }


    // =================================================================
    // 🎡 [엄지 전용 가동 연쇄 영역]: 2마디(토마토색) 관절 구동 매커니즘 완결
    // =================================================================
    rotate([current_angle, 0, 0]) {
        color("Tomato") middle_segment();
        
        // ✂️ [엄지 패치 영구 적용]: 
        // 토마토색 마디 내부에 이미 구슬 코어가 완벽히 매칭되어 출력되므로,
        // 기존에 하단 소켓 밖으로 유령처럼 삐져나오던 3번째 translate 구슬 코드는 
        // 2마디 해부학 구조에 맞춰 흔적도 없이 완전히 삭제했습니다.
    }
}




// =================================================================
// 🎬 [애니메이션 인스펙션 연산 및 이중 모드 시각화 스위칭 코드 - 최종 수정본]
// =================================================================
if (view_mode == 2) {
    final_assembled_joint(); // 2번: 부품이 완벽히 맞물려 구동되는 실물 구동 모드
} else if (view_mode == 1) {
    // 1번: 회색 손등뼈부터 토마토색 끝마디까지 전체를 시원하게 반으로 가르는 단면 모드
    difference() {
        final_assembled_joint();
        
        // 🎯 [엄지 칼날 고도 정렬]: 엄지 하부 관절 중심선에 맞추어 완벽하게 단면 절단
        translate([box_size * 2, 0, proximal_bone_h + joint_radius]) 
            cube([box_size * 4, box_size * 4, box_size * 8], center=true); 
    }
} else {
    // 🛠️ 분해 인스펙션 모드 (view_mode = 3): 엄지 2마디 구성품을 사방으로 펼쳐 내부 검수
    explode_distance = finger_w * 1.5; // 부품이 사방으로 벌어질 안전 시각 거리
    
    // [최상단 소스]: 회색 손등뼈 (정밀 동축 Y축 0선 고정)
    color("LightGray")
        translate([0, 0, proximal_bone_h + joint_radius * 2 + explode_distance])
            rotate([0, 0, 0]) // 🎯 [오타 수정]: 비어있던 rotate 괄호 안에 기본 축 인자 명시
                metacarpal_bone();

    // 1. [좌측 배치]: 1번째 마디(하늘색) 
    color("LightBlue") 
        translate([-explode_distance, 0, 0]) proximal_segment(); 
    
    // 2. [중앙 상단]: 상부 관절용 표준 구슬 코어 (연두색)
    color("Lime") 
        translate([0, 0, joint_radius]) // 🎯 [버그 픽스]: 비어있던 translate 괄호에 정렬 좌표 주입!
            independent_ball_bearing(); 
        
    // 3. [중앙 하단]: 엄지 최종 하부 관절용 표준 구슬 코어 (연두색)
    color("Lime")
        translate([0, 0, -(proximal_bone_h + joint_radius * 2) - explode_distance]) 
            independent_ball_bearing();

    // 4. [우측 배치]: 2번째 마디(토마토색 - 최종 마디)
    color("Tomato") 
        translate([explode_distance, 0, 0]) 
            middle_segment(); 

    // ✂️ 일반 손가락용 3마디(tip_segment) 잔재 데이터 완전 삭제 완료
}
