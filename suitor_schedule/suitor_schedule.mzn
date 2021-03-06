% scheduling suitors
enum SUITOR;
SUITOR: LiuBei; % which suitor is LiuBei
int: n; % number of meetings
set of int: MEETING = 1..n;
array[MEETING] of SUITOR: suitor;

enum ROOM = { Red, Gold, Blue };
array[SUITOR,ROOM] of int: mintime;
array[SUITOR,ROOM] of int: maxtime;
constraint forall(s in SUITOR, r in ROOM)
                 (assert(mintime[s,r] >= 1 /\ maxtime[s,r] >= mintime[s,r], 
                  "error in mintime/maxtime at [\(s),\(r)]\n"));

array[ROOM,ROOM] of int: move;
constraint forall(r in ROOM)(assert(move[r,r] = 0,"move[\(r),\(r)] != 0\n"));

int: ndays; % number of days
set of int: DAY = 1..ndays;
int: earliest; % time for earliest meeting start
int: latest;  % time for end of latest meeting

int: lessontime; % time for kung fu lesson;
int: minsep;     % minimum time between consecutive kung fu lessons

array[ROOM] of int: usedstart;  % time others use each room each day
array[ROOM] of int: useddur;    % durations of others use

enum STAGE = {A,B,C};
STAGE: stage;

set of int: TIME = 0..24*ndays;

array[MEETING] of var TIME: start;
array[MEETING] of var TIME: dur;    % duration in false schedule
array[MEETING] of var ROOM: room;
set of int: KUNGFU = 1..n;
array[KUNGFU] of var int: kungfu;  % start time for each lesson
   % unused lessons have start times after 24*ndays


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For every meeting, it cannot start earlier than earliest
% For every meeting, it cannot end later than latest
constraint forall(m in MEETING) (
    (start[m] mod 24) >= earliest /\
    (start[m] mod 24) <= latest /\
    ((start[m] + dur[m]) mod 24) >= earliest /\
    ((start[m] + dur[m]) mod 24) <= latest
);

% For every meeting, it cannot last longer than maxtime
% For every meeting, it cannot shorter longer than mintime
constraint forall(m in MEETING) (
    dur[m] - followed[m]*lessontime >= mintime[suitor[m], room[m]] /\
    dur[m] <= maxtime[suitor[m], room[m]]
);

% For every meeting, they cannot overlap with each other
% And also consider the transition time
constraint forall(m1, m2 in MEETING where m1 < m2) (
    start[m1] + dur[m1] + move[room[m1], room[m2]] <= start[m2] \/
    start[m2] + dur[m2] + move[room[m1], room[m2]] <= start[m1]
);

% Suitors meeting cannot falls in reserved time
constraint forall(m in MEETING) (
    usedstart[room[m]] + useddur[room[m]] <= (start[m] mod 24)\/
    (start[m] + dur[m]) mod 24 <= usedstart[room[m]]
);

% Dis-allow combination
constraint forall(s in SUITOR) (
    forall(m1, m2 in MEETING where suitor[m1] = s /\ suitor[m2] = s /\ m1 < m2)(
        start[m1] < start[m2]
    )
);

% Just assume than kungfu all greater than 0
constraint forall(k in KUNGFU) (
    kungfu[k] > 0 /\
    kungfu[k] <= 24*ndays + n*(minsep+lessontime)
);

% Mark following
array[KUNGFU] of var 0..n: kTm;
array[MEETING] of var 0..1: followed;
constraint forall(m in MEETING)(
    stage != C -> followed[m] = 0
);
constraint forall(k in KUNGFU)(
    stage != C -> kTm[k] = 0
);

% Kungfu align with the end of a meeting
constraint forall(k in KUNGFU  where (kungfu[k] <= 24*ndays) ) (
    if stage != C then true else
    exists(m in MEETING)(kungfu[k] + lessontime = start[m] + dur[m] /\ kTm[k] = m)
    endif
);

constraint forall(m in MEETING)(
    if stage != C then true else
    if exists(k in KUNGFU)(kTm[k] = m) then followed[m] = 1 else followed[m] = 0 endif
    endif
);




% Kungfu order increasing and satisfy minsep
constraint forall(k in 1..n-1) (
    kungfu[k] + minsep + lessontime <= kungfu[k+1]
);

% For stage A, B only
constraint forall(k in KUNGFU) (
    stage != C -> kungfu[k] > 24*ndays
);

var int: objA = sum(m in MEETING where suitor[m] = LiuBei)(dur[m]);

% Obj for stage C
% Time for Liu Bei
var int: obj1 = sum(m in MEETING where suitor[m] = LiuBei)(dur[m] - followed[m]*lessontime);
% Time for Kungfu
var int: obj2 = sum(k in KUNGFU )(if (kungfu[k] < 24*ndays) then 1 else 0 endif);
var int: objC = 100*obj2 + obj1;

var int: obj;
constraint if stage != C then obj = objA else obj = objC endif;

solve maximize obj;

output
       ["start = ["] ++ [show_int(2, start[m]) ++ if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["dur  = ["] ++ [show_int(2, dur[m]) ++  if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["room = ["] ++ [show(room[m]) ++  if m != n then ", " else "" endif | m in MEETING] ++ ["];\n"]
       ++ ["kungfu = ["] ++ [show(kungfu[k]) ++  if k != n then ", " else "" endif | k in KUNGFU] ++ ["];\n"]
       ++ ["obj = " ++ show(obj) ++ ";"]
       ;



