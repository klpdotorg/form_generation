-- For return value
whenever sqlerror exit sql.sqlcode

-- Headers just once
set emb on pages 0 newp 0
set und off

set colsep |
set pages 0
set newpage none
set feedback off
set echo off
set trimspool on
set termout off
set array 100
set tab off
set linesize 10000

spool circles

select distinct b.name,b.id_bndry from eg_boundary b,eg_school s where s.id_adm_boundary=b.id_bndry and s.id in (30444, 30835, 33998, 31455, 30346, 34153, 30275, 34059, 34078, 31418, 33980, 30467, 31165, 31166, 30449, 33890, 33870, 31493, 33832, 30841, 30862, 31499, 30845, 33828, 33884, 30984, 30456, 31298, 34094, 30584, 33816, 33876, 34072, 31080, 31072, 31412, 30697, 31078, 31107, 29588, 29592, 29598, 30624, 34157, 30632, 29675, 29621, 29705, 33597, 33585, 31490, 30928, 33618, 33654, 29564, 30788, 33575, 33581, 30821, 33570, 29590, 33548, 34003, 30912, 30909, 30892, 33942, 30820, 33602, 33720, 33719, 33461, 33973, 33672, 33637, 30907, 30913, 33678, 33459, 30394, 30383, 29549, 29548, 30220, 33748, 33764, 33778, 31113, 31144, 31374, 29672, 29670, 29693, 31116, 31142, 33799, 33842, 33837, 30377, 30511, 30498, 30500,31386, 31486, 30685, 31327, 31304, 31309, 33765, 33753, 30647, 33802, 30671, 33829, 31443, 29708, 30541, 30943, 30644, 31365, 29614, 29619, 29694, 30407, 30972, 31361, 30593, 33460, 30631, 31290, 33726, 33796, 34064, 30977, 34043, 31510, 31280, 30880, 30822, 30824, 30475, 31042, 31207, 30535, 31302, 30728, 30766, 30226, 33860, 29662, 31383, 31351, 33818, 30349, 30307, 30347, 30759, 33838, 33727, 31512, 31243, 33839, 33990, 33991,33665,31542,33854,31306,33939,31541);

spool off
exit sql.sqlcode
