(*
100 ' VS (ｳﾞｧｰｻｽ)   STAGE 1           (C) 1993.02.03 VIC MAN    Origianl
110 '
1000 '                       INIT 1
1010 WIDTH 40,25:CONSOLE 0,25,0,1,1:CLS
1020 BS$=CHR$(&H1F)+CHR$(&H1D)
1030 PB$(1)="█"
1040 PB$(3)="█"+BS$+"█"+BS$+"█"
1050 PB$(5)="█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"
1060 PB$(7)="█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"
1070 PB$(9)="█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"+BS$+"█"
1090 '
1095 DIM PO$(5,5)
1100 FOR I=1 TO 5
1110    READ PO$(0,I),PO$(1,I),PO$(2,I),PO$(3,I),PO$(4,I),PO$(5,I)
1120 NEXT
1130 '     ----+   ----+   ----+   ----+   ----+   ----+
1140 DATA "█████","  ██ ","█████","█████","██   ","█████"
1150 DATA "██  █","████ ","    █","   ██","██ █ ","██   "
1160 DATA "██  █","  ██ ","█████","█████","██ █ ","█████"
1170 DATA "██  █","  ██ ","██   ","   ██","█████","    █"
1180 DATA "█████","█████","█████","█████","   █ ","█████"
1190 '
1200 BX=20:BY=12:BXV=1:BYV=1:P1=0:P2=0:PMAX=5:TT=100
1990 '
2000 '                       MENU
2010 CLS:COLOR 7
2020 '      ----+----1----+----2----+----3----+----4
2030 PRINT "        ▁▁▁▁    ▁▁                     "
2040 PRINT "        ██ ▕    ██    ███████          "
2050 PRINT "        ██ ▕▁   ██    ██ ▕             ":COLOR 5
2060 PRINT "         ██ ▕▁ ██     ███████          "
2070 PRINT "          ██  ██           ██          ":COLOR 1
2080 PRINT "           ████       ███████          "
2090 PRINT "                                       ":COLOR 4
2100 PRINT "       ---== BALL & FIER ==---         ":COLOR 7
2110 PRINT "                                       "
2120 PRINT "          VS  HUMAN                    "
2130 PRINT "          VS  COMPUTER RANDER          "
2140 PRINT "          VS  COMPUTER NOMAC           "
2150 PRINT "          VS  COMPUTER WINNIX          "
2160 PRINT "          VS  COMPUTER PRO+            ":COLOR 3
2170 PRINT "    1 PLAYER SELECT AND PUSH 0 KEY     "
2180 PRINT "                                       ":COLOR 7
2190 PRINT "  2 PLAYER                   1 PLAYER  "
2200 PRINT "                                       "
2210 PRINT "  TAB                               *  "
2220 PRINT "  +      X = FIER        0= FIER    +  "
2230 PRINT "  SHIFT                             =  "
2240 PRINT "                                       ":COLOR 2
2250 PRINT "                    (C)1993.02  VIC MAN":COLOR 7
2260 '
2300 COL=0:WHILE INKEY$<>"":WEND
2310 LOCATE 7,9+COL :COLOR 2:PRINT "->"
2320    A$=INKEY$:BEEP 0
2330    IF A$="" THEN 2320
2340    LOCATE 7,9+COL :COLOR 7:PRINT "  "
2350    IF A$="*" AND COL>0 THEN COL=COL-1:BEEP 1
2360    IF A$="=" AND COL<4 THEN COL=COL+1:BEEP 1
2370 IF A$<>"0" THEN 2310
2990 '
3000 '                       INIT 2
3010 Y1=18:B1=5:L1=-1
3020 Y2= 1:B2=5:L2=40
3030 BX=20:BY=12:MS=0
3100 '
3110 CLS:COLOR 7
3120 LOCATE  0, 0:PRINT " "+STRING$(38,"█")+" "
3130 LOCATE  0,23:PRINT " "+STRING$(38,"█")+CHR$(11)
3140 COLOR 1:LOCATE 38,Y1:PRINT PB$(B1);
3145 'COLOR 1:LOCATE 38,Y1:PRINT CHR$(8)+CHR$(8)+PB$(B1);    :FOR PC-88
3150 COLOR 2:LOCATE  1,Y2:PRINT PB$(B2);
3160 COLOR 7:LOCATE BX,BY:PRINT "⚫"
3200 '
3210 COLOR 4:LOCATE 15, 8:PRINT "========"
3220         LOCATE 15, 9:PRINT " PLAY ! "
3230         LOCATE 15,10:PRINT "========"
3240 FOR T=0 TO 1500+TT*5:NEXT
3250 COLOR 7:LOCATE 15, 8:PRINT "        "
3260         LOCATE 15, 9:PRINT "        "
3270         LOCATE 15,10:PRINT "        "
3990 '
4000 '                       MAIN
4010 WHILE MS=0
4020    GOSUB 5000:'                        1 PLAYER SUB
4025    GOSUB 6000:'                        2 PLAYER SUB
4030    GOSUB 5000:'                        1 PLAYER SUB
4035    GOSUB 6000:'                        2 PLAYER SUB
4040    GOSUB 8000:'                        BALL     SUB
4050 WEND
4060 GOSUB 9000:   '                        POINT    SUB
4070 IF P1=PMAX OR P2=PMAX THEN ELSE 3000:' INII 2
4080 GOTO  10000:  '                        GAME OVER SUB
4990 '
5000 '                       1 PLAYER
5010 I0=NOT(INP(&HE0))
5020 I1=NOT(INP(&HE1))
5030 IF I0+I1=510 THEN 5200
5040 IF (I1 AND  4)= 4 AND Y1>1 THEN ELSE 5100
5050    COLOR 7:LOCATE 38,Y1+B1-1:PRINT " "
5060    Y1=Y1-1
5070    COLOR 1:LOCATE 38,Y1:PRINT PB$(B1);
5100 '
5110 IF (I1 AND 16)=16 AND Y1+B1<23 THEN ELSE 5200
5120    COLOR 7:LOCATE 38,Y1     :PRINT " "
5130    Y1=Y1+1
5140    COLOR 1:LOCATE 38,Y1:PRINT PB$(B1);
5200 '
5210 IF (I0 AND  1)= 1 OR L1<>-1 THEN ELSE 5400
5220    IF L1=-1 THEN L1=47:LX1=37:LY1=Y1+INT(B1/2)
5230    COLOR 5
5240    IF LX1>=0 THEN LOCATE LX1,LY1:PRINT "‒"
5250    IF L1 <38 THEN LOCATE L1 ,LY1:PRINT " "
5260    IF (L1>0 AND L1<11) AND (LY1>=Y2 AND LY1<Y2+B2) AND B2>1 THEN ELSE 5300
5270       B1=B1+2:Y1=Y1-2:B2=B2-2:LOCATE 1,Y2+B2:PRINT " "+BS$+" ":BEEP 1:                IF Y1<1 THEN Y1=1
5280       COLOR 1:LOCATE 38,Y1:PRINT PB$(B1);
5290       COLOR 2:LOCATE  1,Y2:PRINT PB$(B2);
5300    LX1=LX1-1:L1=L1-1
5400 '
5500 RETURN
6000 '                       2 PLAYER
6010 I0=NOT(INP(&HE8))
6020 I1=NOT(INP(&HEA)):I2=NOT(INP(&HE5))
6025 IF COL>0 THEN GOSUB 7000
6030 IF I0+I1+I2=765 THEN 6200
6040 IF (I1 AND  1)= 1 AND Y2>1 THEN ELSE 6100
6050    COLOR 7:LOCATE  1,Y2+B2-1:PRINT " "
6060    Y2=Y2-1
6070    COLOR 2:LOCATE  1,Y2:PRINT PB$(B2);
6100 '
6110 IF (I0 AND 64)=64 AND Y2+B2<23 THEN ELSE 6200
6120    COLOR 7:LOCATE  1,Y2     :PRINT " "
6130    Y2=Y2+1
6140    COLOR 2:LOCATE  1,Y2:PRINT PB$(B2);
6200 '
6210 IF (I2 AND  1)= 1 OR L2<>40 THEN ELSE 6400
6220    IF L2=40 THEN L2=-9:LX2=2:LY2=Y2+INT(B2/2)
6230    COLOR 3
6240    IF LX2<40 THEN LOCATE LX2,LY2:PRINT "‒"
6250    IF L2 >=2 THEN LOCATE L2 ,LY2:PRINT " "
6260    IF (L2>28 AND L1<39) AND (LY2>=Y1 AND LY2<Y1+B1) AND B1>1 THEN ELSE 6300
6270       B2=B2+2:Y2=Y2-2:B1=B1-2:LOCATE 38,Y1+B1:PRINT " "+BS$+" ":BEEP 1:                IF Y2<1 THEN Y2=1
6280       COLOR 1:LOCATE 38,Y1:PRINT PB$(B1);
6290       COLOR 2:LOCATE  1,Y2:PRINT PB$(B2);
6300    LX2=LX2+1:L2=L2+1
6400 '
6500 RETURN
6990 '
7000 '                       COMPUTER PLAY
7010 ON COL GOSUB 7100,7300,7500,7700
7020 RETURN
7090 '
7100 '                       COMPUTER RANDER
7110 I0=255:I1=255:I2=255
7120 RAN=RND(1)
7130 IF RAN>.36 AND BYV=-1 THEN I0=  1 ELSE I1= 64
7140 IF RAN>.5  THEN I2=  1
7150 RETURN
7190 '
7300 '                       COMPUTER NOMAC
7310 I0=255:I1=255:I2=255
7320 RAN=RND(1)
7330 IF BYV=-1 THEN I0=  1   ELSE I1= 64
7340 IF RAN>.6 AND Y1<BY AND BY<Y1+B1 THEN I2=  1
7350 RETURN
7390 '
7500 '                       COMPUTER WINNIX
7510 I0=255:I1=255:I2=255
7520 RAN=INT(RND(1)*B2)+1
7530 IF SGN(BY-(Y2+RAN/2))=-1 THEN I0= 1  ELSE I1= 64
7540 IF Y1<BY AND BY<Y1+B1 THEN I2=  1
7550 RAN=RND(1)
7560 IF RAN>.9 AND I0= 1 THEN I0=255
7570 IF RAN>.9 AND I1=64 THEN I1=255
7580 RETURN
7590 '
7700 '                       COMPUTER PRO+
7710 I0=255:I1=255:I2=255  'I0=ｼﾀ:I1=ｳｴ:I2=ﾚｰｻﾞｰ
7720 IF BX<5 OR (BX<20 AND BXV<0)THEN ELSE 7770
7730   CT=Y2+B2¥2-BY       'ﾎﾞｰﾙｶﾞｷﾃｲﾙ
7740   IF CT>0 THEN I0=1 ELSE I1=64
7750   IF RND>.98 THEN I2=1
7760 RETURN
7770   IF BX>20 OR RND>.8 THEN I2=1
7780   IF LX1>20 THEN 7790
7785   IF Y2<=LY1 AND Y2+B2>=LY1 THEN IF LY1<12 THEN I1=64 ELSE I0=1
7790   IF RND>.98 THEN I0=255:I1= 64
7800   IF RND>.98 THEN I0=  1:I1=255
7810 RETURN
7820 '
8000 '                       BALL
8010 COLOR 7:LOCATE BX,BY:PRINT " "
8020 BX=BX+BXV
8030 BY=BY+BYV
8040 IF BX= 1 THEN IF (Y2<=BY AND BY<=Y2+B2) THEN BXV=-BXV:BX=BX+BXV:BEEP 1
8045 IF BX= 2 AND BY=1 THEN IF (Y2<=BY AND BY<=Y2+B2) THEN BXV=-BXV:BX= 2:BYV=-BYV:BEEP 1:GOTO 8080
8050 IF BX=38 THEN IF (Y1<=BY AND BY<=Y1+B1) THEN BXV=-BXV:BX=BX+BXV:BEEP 1
8055 IF BX=37 AND BY=1 THEN IF (Y1<=BY AND BY<=Y1+B1) THEN BXV=-BXV:BX=37:BYV=-BYV:BY=1:BEEP 1:GOTO 8080
8060 IF BX=0 OR BX=39 THEN MS=1
8070 IF BY=0 OR BY=23 THEN BYV=-BYV:BY=BY+BYV:BEEP 1
8080 COLOR 7:LOCATE BX,BY:PRINT "⚫"
8090 BEEP 0
8095 FOR T=0 TO TT:NEXT
8100 RETURN
8990 '
9000 '                       POINT
9005 FOR T=0 TO 50:BEEP 1:FOR I=0 TO 5:NEXT:BEEP 0:NEXT
9010 IF BX= 0 THEN P1=P1+1
9020 IF BX=39 THEN P2=P2+1
9030 FOR I=1 TO 5
9040     COLOR 2:LOCATE 10,8+I:PRINT PO$(P2,I)
9050     COLOR 1:LOCATE 25,8+I:PRINT PO$(P1,I)
9060 NEXT
9070 FOR T=0 TO 1500+TT*5:NEXT
9080 MS=0:BXV=-BXV
9090 RETURN
9990 '
10000 '                      GAME OVER
10010 IF P1=PMAX THEN WIN=1 ELSE WIN=2
10020 FOR I=1 TO 5
10030    COLOR WIN:LOCATE  7,15+I:PRINT PO$(WIN,I)
10040 NEXT
10050 '                   ----+----1----+----2
10060 LOCATE 14,15:PRINT "████ ██ █ █        "
10070 LOCATE 14,16:PRINT "█  █ ██ █ █        "
10080 LOCATE 14,17:PRINT "████ ██ █ █ ███ █  █"
10090 LOCATE 14,18:PRINT "█    ██ █ █  █  ██ █"
10100 LOCATE 14,19:PRINT "█    ██ █ █  █  █ ██"
10110 LOCATE 14,20:PRINT "█     ████  ███ █  █"
10120 '
10200 FOR T=0 TO 15000+TT*10:NEXT
10210 RUN
20000 COLOR 7:WIDTH 80:EDIT .
*)

let junk (q: 'a Queue.t): unit = (
	let (_: 'a) = Queue.take q in
	()
);;

let repeat (n: int) (s: string) = (
	let r = Buffer.create (n * String.length s) in
	for i = 1 to n do
		Buffer.add_string r s
	done;
	Buffer.contents r
);;

let wait (n: int) = Terminal.sleep (float_of_int n /. 1000.0);;

let beep (n: int) = ();; (* dummy *)

let sgn (x: int) = if x > 0 then +1 else if x < 0 then -1 else 0;;

let hbar = "‒";;
let fill = "█";;
let ball = "⚫";;

let rec run (stdout, stdin: Unix.file_descr * Unix.file_descr): unit = (
	let cls () = Terminal.Descr.clear_screen stdout () in
	let print = Terminal.Descr.output_string stdout in
	let nl () = Terminal.Descr.output_newline stdout () in
	let bs () = Terminal.Descr.move stdout (-1) (+1) in
	let color n = (
		let c =
			match n with
			| 0 -> Terminal.black
			| 1 -> Terminal.blue
			| 2 -> Terminal.red
			| 3 -> Terminal.magenta
			| 4 -> Terminal.green
			| 5 -> Terminal.cyan
			| 6 -> Terminal.yellow
			| 7 -> Terminal.white
			| _ -> assert false
		in
		Terminal.Descr.color stdout ~foreground:c ()
	) in
	let locate x y = Terminal.Descr.set_position stdout x y in
	let inkey: string Queue.t = Queue.create () in
	let rec do_events (wait: bool) = (
		if wait || not (Terminal.Descr.is_empty stdin) then (
			let ev = Terminal.Descr.input_event stdin in
			if Terminal.is_string ev then (
				Queue.add (String.uppercase (Terminal.string_of_event ev)) inkey;
				do_events false
			) else (
				do_events wait
			)
		)
	) in
	let p1_control = ref 0 in
	let p1_fire = ref false in
	let p2_control = ref 0 in
	let p2_fire = ref false in
	(* INIT 1 *)
	let pb (height: int): unit = (
		for i = 1 to height do
			print fill;
			bs ()
		done
	) in
	let po_data = [|
		(*  ----+    ----+    ----+    ----+    ----+    ----+ *)
		[| "█████"; "  ██ "; "█████"; "█████"; "██   "; "█████" |];
		[| "██  █"; "████ "; "    █"; "   ██"; "██ █ "; "██   " |];
		[| "██  █"; "  ██ "; "█████"; "█████"; "██ █ "; "█████" |];
		[| "██  █"; "  ██ "; "██   "; "   ██"; "█████"; "    █" |];
		[| "█████"; "█████"; "█████"; "█████"; "   █ "; "█████" |] |]
	in
	let po (n: int): unit = (
		for y = 0 to 4 do
			print po_data.(y).(n);
			Terminal.Descr.move stdout (-5) (+1);
		done
	) in
	let bx = ref 20 in
	let by = ref 12 in
	let bxv = ref 1 in
	let byv = ref 1 in
	let p1 = ref 0 in
	let p2 = ref 0 in
	let pmax = 5 in
	let tt = 100 in
	(* MENU *)
	cls ();
	color 7;
	(*     ----+----1----+----2----+----3----+----4 *)
	print "        ▁▁▁▁    ▁▁                     "; nl ();
	print "        ██ ▕    ██    ███████          "; nl ();
	print "        ██ ▕▁   ██    ██ ▕             "; nl (); color 5;
	print "         ██ ▕▁ ██     ███████          "; nl ();
	print "          ██  ██           ██          "; nl (); color 1;
	print "           ████       ███████          "; nl ();
	print "                                       "; nl (); color 4;
	print "       ---== BALL & FIER ==---         "; nl (); color 7;
	print "                                       "; nl ();
	print "          VS  HUMAN                    "; nl ();
	print "          VS  COMPUTER RANDER          "; nl ();
	print "          VS  COMPUTER NOMAC           "; nl ();
	print "          VS  COMPUTER WINNIX          "; nl ();
	print "          VS  COMPUTER PRO+            "; nl (); color 3;
	print "    1 PLAYER SELECT AND PUSH 0 KEY     "; nl ();
	print "                                       "; nl (); color 7;
	print "  2 PLAYER                   1 PLAYER  "; nl ();
	print "                                       "; nl ();
	print "  Q                                 O  "; nl ();
	print "  +      X = FIER        0= FIER    +  "; nl ();
	print "  A                                 L  "; nl ();
	print "                                       "; nl (); color 2;
	print "                    (C)1993.02  VIC MAN"; nl (); color 7;
	let col = ref 0 in
	while Queue.is_empty inkey do
		do_events true
	done;
	junk inkey;
	let a = ref "" in
	while !a <> "0" do
		locate 7 (9 + !col); color 2; print "->";
		if Queue.is_empty inkey then do_events true;
		a := Queue.take inkey;
		beep 0;
		locate 7 (9 + !col); color 7; print "  ";
		if !a = "O" && !col > 0 then (decr col; beep 1);
		if !a = "L" && !col < 4 then (incr col; beep 1);
	done;
	let y1 = ref 0 in
	let b1 = ref 0 in
	let l1 = ref 0 in
	let y2 = ref 0 in
	let b2 = ref 0 in
	let l2 = ref 0 in
	let ms = ref 0 in
	let lx1 = ref 0 in
	let ly1 = ref 0 in
	let lx2 = ref 0 in
	let ly2 = ref 0 in
	let rec goto_3000 () = (
		(* INIT 2 *)
		y1 := 18; b1 := 5; l1 := -1;
		y2 := 1; b2 := 5; l2 := 40;
		bx := 20; by := 12; ms := 0;
		cls (); color 7;
		locate 0 0; print (" " ^ repeat 38 fill ^ " ");
		locate 0 23; print (" " ^ repeat 38 fill ^ " ");
		color 1; locate 38 !y1; pb !b1;
		color 2; locate 1 !y2; pb !b2;
		color 7; locate !bx !by; print ball;
		color 4; locate 15  8; print "========";
					locate 15  9; print " PLAY ! ";
					locate 15 10; print "========";
		wait (1500 + tt * 5);
		color 7; locate 15  8; print "        ";
					locate 15  9; print "        ";
					locate 15 10; print "        ";
		while !ms = 0 do
			p1_control := 0;
			p1_fire := false;
			p2_control := 0;
			p2_fire := false;
			do_events false;
			while not (Queue.is_empty inkey) do
				match Queue.take inkey with
				| "O" -> decr p1_control
				| "L" -> incr p1_control
				| "0" -> p1_fire := true
				| "Q" -> decr p2_control
				| "A" -> incr p2_control
				| "X" -> p2_fire := true
				| _ -> ()
			done;
			gosub_5000 (); (* 1 PLAYER SUB *)
			gosub_6000 (); (* 2 PLAYER SUB *)
			gosub_5000 (); (* 1 PLAYER SUB *)
			gosub_6000 (); (* 2 PLAYER SUB *)
			gosub_8000 (); (* BALL     SUB *)
		done;
		gosub_9000 (); (* POINT    SUB *)
		if not (!p1 = pmax || !p2 = pmax) then goto_3000 () (* INII 2 *) else
		goto_10000 () (* GAME OVER SUB *)
	) and gosub_5000 () = (
		(* 1 PLAYER *)
		if !p1_control < 0 && !y1 > 1 then (
			color 7; locate 38 (!y1 + !b1 - 1); print " ";
			y1 := !y1 - 1;
			color 1; locate 38 !y1; pb !b1
		) else if !p1_control > 0 && !y1 + !b1 < 23 then (
			color 7; locate 38 !y1; print " ";
			y1 := !y1 + 1;
			color 1; locate 38 !y1; pb !b1
		);
		if !p1_fire || !l1 <> -1 then (
			if !l1 = -1 then (
				l1 := 47; lx1 :=37; ly1 := !y1 + !b1 / 2;
			);
			color 5;
			if !lx1 >= 0 then (
				locate !lx1 !ly1; print hbar
			);
			if !l1 < 38 then (
				locate !l1 !ly1; print " "
			);
			if !l1 > 0 && !l1 < 11 && !ly1 >= !y2 && !ly1 < !y2 + !b2 && !b2 > 1 then (
				b1 := !b1 + 2; y1 := !y1 - 2; b2 := !b2 - 2;
				locate 1 (!y2 + !b2); print " "; bs (); print " "; beep 1;
				if !y1 < 1 then y1 := 1;
				color 1; locate 38 !y1; pb !b1;
				color 2; locate 1 !y2; pb !b2
			);
			lx1 := !lx1 - 1; l1 := !l1 - 1
		)
	) and gosub_6000 () = (
		if !col > 0 then gosub_7000 ();
		if !p2_control < 0 && !y2 > 1 then (
			color 7; locate 1 (!y2 + !b2 - 1); print " ";
			y2 := !y2 - 1;
			color 2; locate 1 !y2; pb !b2
		) else if !p2_control > 0 && !y2 + !b2 < 23 then (
			color 7; locate 1 !y2; print " ";
			y2 := !y2 + 1;
			color 2; locate 1 !y2; pb !b2
		);
		if !p2_fire || !l2 <> 40 then (
			if !l2 = 40 then (
				l2 := -9; lx2 := 2; ly2 := !y2 + !b2 / 2
			);
			color 3;
			if !lx2 < 40 then (
				locate !lx2 !ly2; print hbar
			);
			if !l2 >=2 then (
				locate !l2 !ly2; print " "
			);
			if !l2 > 28 && !l1 < 39 && !ly2 >= !y1 && !ly2 < !y1 + !b1 && !b1 > 1 then (
				b2 := !b2 + 2; y2 := !y2 - 2; b1 := !b1 - 2;
				locate 38 (!y1 + !b1); print " "; bs (); print " "; beep 1;
				if !y2 < 1 then y2 := 1;
				color 1; locate 38 !y1; pb !b1;
				color 2; locate 1 !y2; pb !b2
			);
			lx2 := !lx2 + 1; l2 := !l2 + 1
		)
	) and gosub_7000 () = (
		(* COMPUTER PLAY *)
		match !col with
		| 1 -> gosub_7100 ()
		| 2 -> gosub_7300 ()
		| 3 -> gosub_7500 ()
		| 4 -> gosub_7700 ()
		| _ -> assert false
	) and gosub_7100 () = (
		(* COMPUTER RANDER *)
		p2_control := 0; p2_fire := false;
		let ran = Random.float 1.0 in
		if ran > 0.36 && !byv = -1 then p2_control := -1 else p2_control := +1;
		if ran > 0.5 then p2_fire := true
	) and gosub_7300 () = (
		(* COMPUTER NOMAC *)
		p2_control := 0; p2_fire := false;
		let ran = Random.float 1.0 in
		if !byv = -1 then p2_control := -1 else p2_control := +1;
		if ran > 0.6 && !y1 < !by && !by < !y1 + !b1 then p2_fire := true
	) and gosub_7500 () = (
		(* COMPUTER WINNIX *)
		p2_control := 0; p2_fire := false;
		let ran = Random.int !b2 + 1 in
		if sgn (2 * !by - (2 * !y2 + ran)) = -1 then p2_control := -1 else p2_control := +1;
		if !y1 < !by && !by < !y1 + !b1 then p2_fire := true;
		let ran = Random.float 1.0 in
		if ran > 0.9 && !p2_control = -1 then p2_control := 0;
		if ran > 0.9 && !p2_control = +1 then p2_control := 0
	) and gosub_7700 () = (
		(* COMPUTER PRO+ *)
		p2_control := 0; p2_fire := false; (* I0=ｼﾀ:I1=ｳｴ:I2=ﾚｰｻﾞｰ *)
		if !bx < 5 || (!bx < 20 && !bxv < 0) then (
			let ct = !y2 + !b2 / 2 - !by in (* ﾎﾞｰﾙｶﾞｷﾃｲﾙ *)
			if ct > 0 then p2_control := -1 else p2_control := +1;
			if Random.float 1.0 > 0.98 then p2_fire := true
		) else (
			if !bx > 20 || Random.float 1.0 > 0.8 then p2_fire := true;
			if not (!lx1 > 20) then (
				if !y2 <= !ly1 && !y2 + !b2 >= !ly1 then (
					if !ly1 < 12 then p2_control := +1 else p2_control := -1
				)
			);
			if Random.float 1.0 > 0.98 then p2_control := +1;
			if Random.float 1.0 > 0.98 then p2_control := -1;
		)
	) and gosub_8000 () = (
		(* BALL *)
		color 7; locate !bx !by; print " ";
		bx := !bx + !bxv;
		by := !by + !byv;
		if !bx = 1 && !y2 <= !by && !by <= !y2 + !b2 then (
			bxv := - !bxv; bx := !bx + !bxv; beep 1
		);
		if !bx = 2 && !by = 1 && !y2 <= !by && !by <= !y2 + !b2 then (
			bxv := - !bxv; bx := 2; byv := - !byv; beep 1
		) else (
			if !bx = 38 && !y1 <= !by && !by <= !y1 + !b1 then (
				bxv := - !bxv; bx := !bx + !bxv; beep 1
			);
			if !bx = 37 && !by = 1 && !y1 <= !by && !by <= !y1 + !b1 then (
				bxv := - !bxv; bx := 37; byv := - !byv; by := 1; beep 1
			) else (
				if !bx = 0 || !bx = 39 then ms := 1;
				if !by = 0 || !by = 23 then (
					byv := - !byv; by := !by + !byv; beep 1
				)
			)
		);
		color 7; locate !bx !by; print ball;
		beep 0;
		wait tt;
	) and gosub_9000 () = (
		(* POINT *)
		for t = 0 to 50 do beep 1; wait 5; beep 0; done;
		if !bx = 0 then incr p1;
		if !bx = 39 then incr p2;
		color 2; locate 10 8; po !p2;
		color 1; locate 25 8; po !p1;
		wait (1500 + tt * 5);
		ms := 0; bxv := - !bxv
	) and goto_10000 () = (
		(* GAME OVER *)
		let win = if !p1 = pmax then 1 else 2 in
		color win; locate 7 15; po win;
		(*                   ----+----1----+----2 *)
		locate 14 15; print "████ ██ █ █        ";
		locate 14 16; print "█  █ ██ █ █        ";
		locate 14 17; print "████ ██ █ █ ███ █  █";
		locate 14 18; print "█    ██ █ █  █  ██ █";
		locate 14 19; print "█    ██ █ █  █  █ ██";
		locate 14 20; print "█     ████  ███ █  █";
		wait (15000 + tt * 10);
		run (stdout, stdin)
	) in
	goto_3000 ()
);;

Sys.catch_break true;;
Random.self_init ();;
let stdout = Unix.stdout in
let stdin = Unix.stdin in
Terminal.Descr.screen stdout ~size:(40, 25) ~cursor:false ~wrap:false
	(fun (stdout: Unix.file_descr) ->
		Terminal.Descr.mode stdin ~echo:false ~canonical:false (fun () ->
			run (stdout, stdin)
		)
	);;
