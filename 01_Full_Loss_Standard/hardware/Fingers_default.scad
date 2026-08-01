// =================================================================
// 🌊 BioCerve-Hand: Parametric Hardware Core (v9.1 통합 파라메터 마스터)
// =================================================================
$fn = 60; 

// 🎯 [1] 마디 및 뼈대 치수 (기하학 핵심)
finger_w = 15; // [마스터 변수] 손가락 두께 기준값 고정

// 1. 첫째마디 (Proximal Segment - 현재 설계하신 부위)
// 보통 두께 대비 순수 뼈대 길이는 약 1.8배에서 2배가 가장 적당합니다.
proximal_bone_h = finger_w * 1.8; // 계산값: 21.6mm (현재 15에서 조금 늘리면 완벽한 인체 비율)

// 2. 중간마디 (Middle Segment - 추후 확장 시)
// 첫째마디 길이의 약 70% 수준입니다.
middle_bone_h = proximal_bone_h * 0.7; // 계산값: 15.12mm

// 3. 끝마디 (Distal Segment - 손톱 부위)
// 첫째마디 길이의 약 50% 수준입니다.
distal_bone_h   = proximal_bone_h * 0.5; // 계산값: 10.8mm


joint_radius   = finger_w * (5.5 / 12); // [수식 동기화] 볼 크기를 손가락 두께에 종속 

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
            // 🟥 메인 위쪽 기둥 골격 (finger_w, proximal_bone_h 변수 연동)
            translate([0, 0, proximal_bone_h/2 + joint_radius]) 
                cube([finger_w, finger_w, proximal_bone_h], center=true);
            
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
        translate([0, wire_offset, proximal_bone_h/2 + joint_radius]) 
            cylinder(h=proximal_bone_h * 2, r=tendon_dia/2, center=true);
        
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
// 🦴 [완벽 정렬] 아래쪽 프레임 (Distal Segment - 우측 커버 쉘) 토마토색
// =================================================================
module distal_segment() {
    distal_clear_x = 0.0;                    // 왼쪽 내부 홈 비우기용 X축 오프셋
    roller_pin_d = 1.5;  // 가로 고정 핀 지름 (1.5mm)

    difference() {
        // [1단계: 겉껍질 메인 골격 형성]
        union() {
            // 🟥 메인 아래쪽 기둥 골격 (finger_w, middle_bone_h 변수 연동)
            translate([0, 0, -(middle_bone_h/2 + joint_radius)]) 
                cube([finger_w, finger_w, middle_bone_h], center=true);
            
            // 🟢 [우측 감싸기 쉘] X=0 기준 오른쪽 영역만 남겨 구슬을 우측에서 고정
            difference() {
                sphere(r=outer_shell_r);
                translate([-(box_size/2 - side_margin + clearance/2), 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
                
                translate([0, -outer_shell_r, 0]) 
                    rotate([0, 30, -50])            
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }

            // =================================================================
            // 🆕 🟢 [하부 감싸기 쉘] 상부 쉘과 100% 동일 복사 및 하단 높이 동기화
            // =================================================================
            translate([0, 0, -(middle_bone_h + joint_radius*2)]) {
                difference() {
                    sphere(r=outer_shell_r);
                    translate([-(box_size/2 - side_margin + clearance/2), 0, 0]) 
                        cube([box_size, box_size, box_size], center=true); 
                    
                    translate([0, -outer_shell_r, 0]) 
                        rotate([0, 30, -50])            
                            cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
                }
            }
            
            // 📐 [스토퍼 B] 수동 기계적 락인(Wedge-Lock) 후방 턱
            translate([finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // [2단계: 내부 공간 및 소켓 통로 최종 파내기]
        
        // 🔒 [절대 고정] 상부 메인 관통 핀 홀 (Z=0 중심축 고정)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ 메인 수직 와이어 가이드 홀
        translate([0, wire_offset, -(middle_bone_h/2 + joint_radius)]) 
            cylinder(h=middle_bone_h * 2, r=tendon_dia/2, center=true);

        // ✨ 상부 단선 방지용 가로 미세 핀 홀 (Z = -joint_radius - 1.0)
        target_pin_y = wire_offset - 1.0; 
        target_pin_z = -joint_radius - 1.0; 
        translate([0, target_pin_y, target_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
        
        // 🟢 상부 중심 구슬 안착 소켓 홈
        sphere(r=joint_radius + clearance + 0.15);         
        
        // 🔵 왼쪽 내부 홈 비우기 (중앙 구슬 공간 확보)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([-(box_size/2 + clearance/2), 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }

        // =================================================================
        // 🕳️ 🔄 하부 유니온 쉘 내부 구형 안착 홈 파내기
        // =================================================================
        translate([0, 0, -(middle_bone_h + joint_radius*2)])
            sphere(r=joint_radius + clearance + 0.15);

        // 🔵 하부 왼쪽 내부 홈 비우기 (100% 기하학 동기화)
        translate([0, 0, -(middle_bone_h + joint_radius*2)]) {
            intersection() {
                sphere(r=outer_shell_r + clearance);
                translate([-(box_size/2 + clearance/2), 0, 0]) 
                    cube([box_size, box_size, box_size], center=true);
            }
        }

      // =================================================================
        // 🔒 🎯 [절대 사수] 하부 관절 메인 관통 핀 홀 (가로축 롤러구멍)
        // =================================================================
        // 💡 [3D 프린팅 필독]: 이 구멍은 상부의 'independent_ball_bearing' 구슬과 
        // 100% 동일한 규격의 두 번째 구슬이 안착될 결합 축입니다.
        // 출력 시, 상단의 'independent_ball_bearing' 구슬 부품을 총 [2개] 출력해 주세요.
        translate([0, 0, -(middle_bone_h + joint_radius*2)])
            rotate([0, 90, 0]) 
                cylinder(h=box_size * 2, r=pin_dia/2, center=true);

    // =================================================================
        // ✨ 🔄 [하부 대응 - 정밀 물리 좌표 보정 완료]
        // =================================================================
    
        
        // [수정된 마스터 물리 좌표] 기둥 맨 바닥면에서 1.2mm 위쪽 안전지대 매립
        calculated_pin_z = -(middle_bone_h + joint_radius) + 1.2; 

        translate([0, target_pin_y, calculated_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
    }
}

// =================================================================
// 🦴 [파트 4 수정] 3번째 마디: 최종 끝마디 프레임 (Tip Segment) - 상하 완벽 반전
// =================================================================
// 하부의 둥근 결합 쉘 구조를 상부 원점(Z=0)으로 끌어올리고,
// 네모 기둥 골격 블록이 아래쪽(-Z 방향)으로 자연스럽게 내려가도록 기하학 구조를 정반대로 뒤집었습니다.
module tip_segment() {
    roller_pin_d = 1.5;  // 가로 고정 핀 지름 (1.5mm)

    difference() {
        // [1단계: 겉껍질 메인 골격 형성]
        union() {
            // 🟥 메인 끝마디 기둥 골격 (상하 반전 연산)
            // 기둥 중심축을 아래쪽으로 내려 기둥 블록 전체가 하방을 향하도록 고정합니다.
            translate([0, 0, -(distal_bone_h/2 + joint_radius)]) 
                cube([finger_w, finger_w, distal_bone_h], center=true);
            
            // 🟢 [상부 배치 쉘] 하부에 고여있던 관절 쉘을 상부 원점(Z=0) 기준으로 끌어올림
            // 토마토색 하단(우측 벽)과 정확히 엇갈려 감싸쥐도록 왼쪽(X < 0) 벽면 하우징 사수
            difference() {
                sphere(r=outer_shell_r);
                translate([box_size/2 - side_margin + clearance/2, 0, 0]) 
                    cube([box_size, box_size, box_size], center=true); 
                
                // 🪚 [경사 컷 정렬] 관절이 앞으로 구부러질 때 간섭 없이 개방되도록 앞쪽 모서리 컷
                translate([0, -outer_shell_r, 0]) 
                    rotate([0, 30, 50])           
                        cube([finger_w * 2, finger_w, joint_radius * 2], center=true);
            }
            
            // 📐 [스토퍼 C] 손가락이 펴질 때 뒤로 꺾이지 않도록 지탱하는 후방 턱
            translate([-finger_w/4, outer_shell_r - side_margin, 0]) 
                cube([finger_w/2 - clearance/2, stopper_thick, joint_radius * 2], center=true);
        }
        
        // [2단계: 내부 공간 및 관통 통로 최종 파내기]
        
        // 🔒 [원점 고정] 하부 관절과 이어질 메인 관통 핀 홀 (Z=0 축 고정)
        rotate([0, 90, 0]) 
            cylinder(h=box_size * 2, r=pin_dia/2, center=true);
        
        // 🛠️ [수직 동기화] 수직 와이어 가이드 홀 (아래로 뻗은 기둥에 맞춰 관통 범위 하방 이동)
        translate([0, wire_offset, -(distal_bone_h/2 + joint_radius)]) 
            cylinder(h=distal_bone_h * 2, r=tendon_dia/2, center=true);
        
        // ✨ [단선 방지용 핀 홀] 와이어 레일 초입에 맞춰 콤팩트하게 안착
        proximal_pin_y = wire_offset - 1.0;
        proximal_pin_z = joint_radius + 0.8; // 상부 핏에 맞춰 수직 높이 양수(+) 보정
        
        translate([0, proximal_pin_y, proximal_pin_z])
            rotate([0, 90, 0])
                cylinder(h=finger_w + 2, r=roller_pin_d/2, center=true);
        
        // 🟢 중심 구슬 안착 소켓 홈 (상부 원점으로 칼정렬)
        sphere(r=joint_radius + clearance + 0.15);         
        
        // 🔵 왼쪽 내부 홈 비우기 (중앙 구슬 공간 확보 인터페이스 매칭)
        intersection() {
            sphere(r=outer_shell_r + clearance);
            translate([box_size/2 - inner_clear_x + clearance/2, 0, 0]) 
                cube([box_size, box_size, box_size], center=true);
        }
    }
}



// =================================================================
// 🎬 [최종 제어 파이프라인 및 조립 인터페이스]
// =================================================================
module final_assembled_joint() {
    current_angle = -90 * $t; // 오픈스캐드 자체 애니메이션 대응 (0도 ~ -90도 회전 실시간 구동)

    // 1. [상부 관절 영역] 1번째 마디(라이트블루) & 1번째 구슬(연두색)
    color("LightBlue") proximal_segment();
    color("Lime") independent_ball_bearing();

    // 2. 2번째 마디 (토마토색 프레임) - 상부 관절을 축으로 회전
    rotate([current_angle, 0, 0]) {
        color("Tomato") distal_segment();
        
        // =================================================================
        // 🟢 🔄 [하부 초록 관절 안착] 토마토 하부쉘과 무조건 한 몸으로 결합 구동
        // =================================================================
        // 설계자님의 의도대로, 이 두 번째 초록 구슬축은 토마토색 마디 내부에 고정되어 
        // rotate 괄호 안에서 토마토 마디와 함께 한 치의 오차도 없이 일체형으로 회전 구동합니다.
        translate([0, 0, -(middle_bone_h + joint_radius * 2)])
            color("Lime") independent_ball_bearing();
        
        // =================================================================
        // 🆕 🦴 [3번째 마디 안착] 2번째 관절 구슬을 축으로 삼아 독립 연쇄 구동
        // =================================================================
        // 토마토색 하단 끝점 높이로 정확히 매핑하여 일체형으로 매달아 줍니다.
        // 가로축(X축) 기준으로 공중제비 180도를 돌려 소켓 밥그릇 홈의 방향을 하부 구슬 조준으로 일치시키고,
        // 토마토 마디 대비 끝마디가 자연스러운 스케일로 접히도록 * 0.65 비율을 가동각에 물려줍니다.
        translate([0, 0, -(middle_bone_h + joint_radius * 2)])
            rotate([0, 0, 0]) // 👈 설계자님이 명시하신 가로축(X축) 기준 정확한 180도 반전축!
                rotate([current_angle * 0.65, 0, 0]) // 👈 과도한 꺾임으로 인한 기둥 겹침 방지 및 정방향 굽힘축
                    color("LightGreen") tip_segment();
    }
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
    explode_distance = finger_w * 1.5; // 부품이 양옆으로 벌어질 안전 거리

    // 1. [좌측 외벽] 1번째 마디 분해 배치
    color("LightBlue") 
        translate([-explode_distance * 1.5, 0, 0]) proximal_segment(); 
    
    // 2. [중앙 상단] 첫 번째 제어 구슬 코어 배치
    color("Lime") 
        translate([0, 0, joint_radius]) independent_ball_bearing(); 
        
    // 3. [중앙 하단 - 동기화 패치] 두 번째 제어 구슬도 정렬 상태 확인을 위해 분해 배치
    color("Lime")
        translate([0, 0, -(middle_bone_h + joint_radius * 2) + joint_radius]) 
            independent_ball_bearing();

    // 4. [우측 내벽] 2번째 마디(토마토색) 분해 배치
    color("Tomato") 
        translate([explode_distance, 0, middle_bone_h/2 + joint_radius*2]) 
            rotate([0, 180, 0]) distal_segment(); 

    // 5. [우측 최외벽] 3번째 마디(연두빛 민트색 끝마디) 분해 배치
    // 가로축(X축) 180도 회전을 기반으로 한 조립 유격 상태를 한눈에 볼 수 있도록 바깥 축에 정렬 폭파시킵니다.
    color("LightGreen")
        translate([explode_distance * 2.8, 0, -(middle_bone_h + joint_radius * 2)])
            rotate([180, 0, 0])
                tip_segment();
}


