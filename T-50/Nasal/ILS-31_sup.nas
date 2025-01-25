# Скрипт поддержки ИЛС-31
# Январь 2012, Сергей "Mercenary_Mercury" Салов

var heading = 0;	# Курс
var heading_int = 0;	# Курс (целое значение, с точностью то демяти градусов)
var heading1 = 0;	# Смещение 1 отметки (центральная)
var heading2 = 0;	# Смещение 2 отметки (левая)
var heading3 = 0;	# Смещение 3 отметки (правая)
var heading1_num = 0;	# Числовое значение 1 отметки (центральная)
var heading2_num = 0;	# Числовое значение 2 отметки (левая)
var heading3_num = 0;	# Числовое значение 3 отметки (правая)

 var ILS_31_gyro = func {
  heading = getprop("mig29/instrumentation/PNP-72-12/heading-indicated-deg");		# Получаем текущий курс
  heading_int = int(heading/10);				# Делим на 10, и получаем целую часть
  heading1_num = heading_int;					# Полученое значение будет первым значением курса для отображения
  heading_int = (heading_int*10);				# Востанавливаем значение курса до полного вида
  heading1 = (heading-heading_int);				# Получаем смещение первой отметки
  heading2 = (heading1+10);					# Получаем смещение второй отметки
  heading3 = (heading1-10);					# Получаем смещение третьей отметки
  if ( heading_int < 10 ) { heading2_num=35; }			# Получаем отображаемое значение курса для второй отметки
   else { heading2_num=(heading1_num-1); }
  if ( heading_int >= 350 ) { heading3_num=0; }		# Получаем отображаемое значение курса для третьей отметки
   else { heading3_num=(heading1_num+1); }
  setprop("mig29/systems/ILS-31/heading1", heading1);
  setprop("mig29/systems/ILS-31/heading2", heading2);
  setprop("mig29/systems/ILS-31/heading3", heading3);
  setprop("mig29/systems/ILS-31/heading1_num", heading1_num);
  setprop("mig29/systems/ILS-31/heading2_num", heading2_num);
  setprop("mig29/systems/ILS-31/heading3_num", heading3_num);
  settimer(ILS_31_gyro,0);
}

# Вывод значения скорости

 var ind_speed = 0;

  var ind_speed_31 = func{
   if (getprop("mig29/systems/ILS-31/on") == 1)
    {
     var ind_speed = getprop("mig29/instrumentation/US-1600/airspeed-kmh");
     var ind_speed = (ind_speed/10);
     var ind_speed = int(ind_speed);
     var ind_speed = (ind_speed*10);
     setprop("mig29/instrumentation/ILS-31/indicated_airspeed", ind_speed);
    }
   settimer(ind_speed_31, 0);
  }

# Вывод значения высоты

 var ind_baro_altitude = 0;
 var ind_radio_altitude = 0;
 var ind_altitude = 0;

  var ind_altitude_31 = func{
   if (getprop("mig29/systems/ILS-31/on") == 1)
    {
     var ind_baro_altitude = getprop("mig29/instrumentation/UV-30-3/indicated-altitude-m");
     var ind_radio_altitude = getprop("mig29/instrumentation/RV-21/altitude");
     if ( ind_baro_altitude > 0)
      {
       var ind_baro_altitude = (ind_baro_altitude/10);
       var ind_baro_altitude = int(ind_baro_altitude);
       var ind_baro_altitude = (ind_baro_altitude*10);
     }
      else { var ind_baro_altitude = 0; }
     if (getprop("mig29/systems/ILS-31/r") == 1) { ind_altitude = ind_radio_altitude; }
      else { ind_altitude = ind_baro_altitude; }
     setprop("mig29/instrumentation/ILS-31/indicated_altitude", ind_altitude);
    }
   settimer(ind_altitude_31, 0);
  }

# Переключатель - "День", "Ночь", "Сетка".

 var DNS31 = func {
  if (getprop("mig29/controls/ILS-31/view-mode") == 0) {setprop("mig29/systems/ILS-31/setka", 1);}
  if (getprop("mig29/controls/ILS-31/view-mode") == 1) {setprop("mig29/systems/ILS-31/texture", "ILS-31_night.png"); setprop("mig29/systems/ILS-31/setka", 0);}
  if (getprop("mig29/controls/ILS-31/view-mode") == 2) {setprop("mig29/systems/ILS-31/texture", "ILS-31_day.png"); setprop("mig29/systems/ILS-31/setka", 0);}
}

# IRHUD.nas
# June 2011, Sergey "Mercenary_Mercury" Salow

var v_factor = 0;
var speed_f = 0;
var speed_m = 0;
var speed_m1 = 0;
var speed_m2 = 0;
var speed_m3 = 0;
var tempvar = 0;
var m1 = 0;
var m2 = 0;
var m3 = 0;
var vs_norm = 0;

 var conv_v2m = func {
  var speed_f = getprop("/velocities/vertical-speed-fps");
  var speed_m = (speed_f*0.3048);
  var tempvar = speed_m;

  if (speed_m > 0 and speed_m < 5) { v_factor = 0.0072; vs_norm = 1;}
  if (speed_m > -5 and speed_m < 0) { v_factor = 0.0072; vs_norm = 1;}
  if (speed_m < 10 and speed_m > 5) { v_factor = 0.0036; vs_norm = 2;}
  if (speed_m > -10 and speed_m < -5) { v_factor = 0.0036; vs_norm = 2;}
  if (speed_m < 20 and speed_m > 10) { v_factor = 0.0018; vs_norm = 4;}
  if (speed_m > -20 and speed_m < -10) { v_factor = 0.0018; vs_norm = 4;}
  if (speed_m < 50 and speed_m > 20) { v_factor = 0.00075; vs_norm = 10;}
  if (speed_m > -50 and speed_m < -20) { v_factor = 0.00075; vs_norm = 10;}
  if (speed_m < 100 and speed_m > 50) { v_factor = 0.00036; vs_norm = 20;}
  if (speed_m > -100 and speed_m < -50) { v_factor = 0.00036; vs_norm = 20;}
  if (speed_m < 200 and speed_m > 100) { v_factor = 0.00018; vs_norm = 40;}
  if (speed_m > -200 and speed_m < -100) { v_factor = 0.00018; vs_norm = 40;}

  if (speed_m > -10 and speed_m < 10) {m1 = 0; m2 = 0; m3 = 0;}
  if (speed_m > -100 and speed_m < -10) {m1 = 0; m2 = 0; m3 = 1;}
  if (speed_m > 10 and speed_m < 100) {m1 = 0; m2 = 0; m3 = 1;}
  if (speed_m > 100) {m1 = 0; m2 = 1; m3 = 2;}
  if (speed_m < -100) {m1 = 0; m2 = 1; m3 = 2;}

  if (tempvar > -1000 and tempvar < 1000) 
 { 
  if (tempvar > -100 and tempvar < 100) { speed_m1 = 0;}
  if (tempvar > 100 and tempvar < 200) { speed_m1 = 1;}
  if (tempvar > -200 and tempvar < -100) { speed_m1 = 1;}
  if (tempvar > 200 and tempvar < 300) { speed_m1 = 2;}
  if (tempvar > -300 and tempvar < -200) { speed_m1 = 2;}
  if (tempvar > 300 and tempvar < 400) { speed_m1 = 3;}
  if (tempvar > -400 and tempvar < -300) { speed_m1 = 3;}
  if (tempvar > 400 and tempvar < 500) { speed_m1 = 4;}
  if (tempvar > -500 and tempvar < -400) { speed_m1 = 4;}
  if (tempvar > 500 and tempvar < 600) { speed_m1 = 5;}
  if (tempvar > -600 and tempvar < -500) { speed_m1 = 5;}
  if (tempvar > 600 and tempvar < 700) { speed_m1 = 6;}
  if (tempvar > -700 and tempvar < -600) { speed_m1 = 6;}
  if (tempvar > 700 and tempvar < 800) { speed_m1 = 7;}
  if (tempvar > -800 and tempvar < -700) { speed_m1 = 7;}
  if (tempvar > 800 and tempvar < 900) { speed_m1 = 8;}
  if (tempvar > -900 and tempvar < -800) { speed_m1 = 8;}
  if (tempvar > 900 and tempvar < 1000) { speed_m1 = 9;}
  if (tempvar > -1000 and tempvar < -900) { speed_m1 = 9;}
  var tempvar = speed_m-(speed_m1*100);
 }
  else {tempvar = speed_m}
  if (tempvar > -100 and tempvar < 100) 
 { 
  if (tempvar > -10 and tempvar < 10) { speed_m2 = 0;}
  if (tempvar > 10 and tempvar < 20) { speed_m2 = 1;}
  if (tempvar > -20 and tempvar < -10) { speed_m2 = 1;}
  if (tempvar > 20 and tempvar < 30) { speed_m2 = 2;}
  if (tempvar > -30 and tempvar < -20) { speed_m2 = 2;}
  if (tempvar > 30 and tempvar < 40) { speed_m2 = 3;}
  if (tempvar > -40 and tempvar < -30) { speed_m2 = 3;}
  if (tempvar > 40 and tempvar < 50) { speed_m2 = 4;}
  if (tempvar > -50 and tempvar < -40) { speed_m2 = 4;}
  if (tempvar > 50 and tempvar < 60) { speed_m2 = 5;}
  if (tempvar > -60 and tempvar < -50) { speed_m2 = 5;}
  if (tempvar > 60 and tempvar < 70) { speed_m2 = 6;}
  if (tempvar > -70 and tempvar < -60) { speed_m2 = 6;}
  if (tempvar > 70 and tempvar < 80) { speed_m2 = 7;}
  if (tempvar > -80 and tempvar < -70) { speed_m2 = 7;}
  if (tempvar > 80 and tempvar < 90) { speed_m2 = 8;}
  if (tempvar > -90 and tempvar < -80) { speed_m2 = 8;}
  if (tempvar > 90 and tempvar < 100) { speed_m2 = 9;}
  if (tempvar > -100 and tempvar < -90) { speed_m2 = 9;}
  var tempvar = tempvar-(speed_m2*10);
 }
  else {tempvar = speed_m}
  if (tempvar > -1 and tempvar < 1) { speed_m3 = 0;}
  if (tempvar > 1 and tempvar < 2) { speed_m3 = 1;}
  if (tempvar > -2 and tempvar < -1) { speed_m3 = 1;}
  if (tempvar > 2 and tempvar < 3) { speed_m3 = 2;}
  if (tempvar > -3 and tempvar < -2) { speed_m3 = 2;}
  if (tempvar > 3 and tempvar < 4) { speed_m3 = 3;}
  if (tempvar > -4 and tempvar < -3) { speed_m3 = 3;}
  if (tempvar > 4 and tempvar < 5) { speed_m3 = 4;}
  if (tempvar > -5 and tempvar < -4) { speed_m3 = 4;}
  if (tempvar > 5 and tempvar < 6) { speed_m3 = 5;}
  if (tempvar > -6 and tempvar < -5) { speed_m3 = 5;}
  if (tempvar > 6 and tempvar < 7) { speed_m3 = 6;}
  if (tempvar > -7 and tempvar < -6) { speed_m3 = 6;}
  if (tempvar > 7 and tempvar < 8) { speed_m3 = 7;}
  if (tempvar > -8 and tempvar < -7) { speed_m3 = 7;}
  if (tempvar > 8 and tempvar < 9) { speed_m3 = 8;}
  if (tempvar > -9 and tempvar < -8) { speed_m3 = 8;}
  if (tempvar > 9 and tempvar < 10) { speed_m3 = 9;}
  if (tempvar > -10 and tempvar < -9) { speed_m3 = 9;}
  setprop("mig29/systems/ILS-31/vertical-speed-mps", speed_m);
  setprop("mig29/instrumentation/ILS-31/vertical-speed-norm-mps", (speed_m/vs_norm));
  setprop("mig29/systems/ILS-31/v-factor", v_factor);
  setprop("mig29/systems/ILS-31/tempvar", tempvar);
  setprop("mig29/systems/ILS-31/speed_m1", speed_m1);
  setprop("mig29/systems/ILS-31/speed_m2", speed_m2);
  setprop("mig29/systems/ILS-31/speed_m3", speed_m3);
  setprop("mig29/systems/ILS-31/m1", m1);
  setprop("mig29/systems/ILS-31/m2", m2);
  setprop("mig29/systems/ILS-31/m3", m3);
  settimer(conv_v2m, 0);
}

#
var navmode_a = 0;
var altb = 0;
var altr = 0;
var offset_digits = 0;

 var ILSaltchg = func {
  var navmode_a = getprop("mig29/nav");
  var altb = getprop("mig29/instrumentation/UV-30-3/indicated-altitude-m");
  var altr = getprop("mig29/instrumentation/RV-21/altitude");
  if (navmode_a == 0 or navmode_a == 2 or navmode_a == 3)
   {
    setprop("mig29/instrumentation/ILS-31/altitude", altr);
    setprop("mig29/instrumentation/ILS-31/p", 1);
   }
  else
   {
   setprop("mig29/instrumentation/ILS-31/altitude", altb);
   setprop("mig29/instrumentation/ILS-31/p", 0);
   }
#  if ()
  settimer(ILSaltchg, 0.05);
}

# Сдвиг цифр высоты
var sda = 0;

 var ILS_sda = func{
  var sda = getprop("mig29/instrumentation/ILS-31/altitude");
  if (sda < 100)
   {
    setprop("mig29/systems/ILS-31/sda100", 3);
    setprop("mig29/systems/ILS-31/sda1000", 3);
    setprop("mig29/systems/ILS-31/sda10000", 3);
   }
  if (sda > 100 and sda < 1000)
   {
    setprop("mig29/systems/ILS-31/sda100", 2);
    setprop("mig29/systems/ILS-31/sda1000", 2);
    setprop("mig29/systems/ILS-31/sda10000", 2);
   }
  if (sda > 1000 and sda < 10000)
   {
    setprop("mig29/systems/ILS-31/sda100", 1);
    setprop("mig29/systems/ILS-31/sda1000", 1);
    setprop("mig29/systems/ILS-31/sda10000", 1);
   }
  if (sda > 10000)
   {
    setprop("mig29/systems/ILS-31/sda100", 0);
    setprop("mig29/systems/ILS-31/sda1000", 0);
    setprop("mig29/systems/ILS-31/sda10000", 0);
   }
  settimer(ILS_sda, 0.05);
}

var ILS_31_tot = 0;

 var ILS_31_t_h = func {
  var ILS_31_tot = getprop("mig29/systems/ILS-31/on");
  if (getprop("mig29/systems/electrical/buses/DC27-bus/volts") > 24 and getprop("mig29/instrumentation/electrical/v115") > 105)
   {
    if (ILS_31_tot == 1) {return;}
    if (ILS_31_tot < 1)
     {var ILS_31_tot = 1-ILS_31_tot; interpolate("mig29/systems/ILS-31/on", 1, ILS_31_tot*30);}
   }
  else
   {if (ILS_31_tot == 0) {return;}
    if (ILS_31_tot > 0)
     {interpolate("mig29/systems/ILS-31/on", 0, ILS_31_tot*30);}
   }
}

 var ILS_31_init = func {
  setprop("mig29/instrumentation/ILS-31/K", 0);
  setprop("mig29/instrumentation/ILS-31/G", 0);
  setprop("mig29/instrumentation/ILS-31/PPM_Aer_range", 0);
  setprop("mig29/instrumentation/ILS-31/indicated-mode", 0);
  setprop("mig29/instrumentation/ILS-31/serviceable", 1);
  setprop("mig29/systems/ILS-31/on", 0);
  ILS_31_gyro();
  ind_speed_31();
  ind_altitude_31();
  DNS31();
  conv_v2m();
  ILSaltchg();
  ILS_sda();
  setlistener("mig29/controls/ILS-31/view-mode", DNS31);
  setlistener("mig29/instrumentation/electrical/v27", ILS_31_t_h);
  setlistener("mig29/instrumentation/electrical/v115", ILS_31_t_h);
}