theory Simple_Network_Language_Certificate_Code
  imports
    Simple_Network_Language_Certificate
    Simple_Network_Language_Export_Code
    Simple_Network_Language_Certificate_Checking
begin

paragraph \<open>Optimized code equations\<close>

lemmas [code_unfold] = imp_for_imp_for'

definition dbm_subset'_impl'_int
  :: "nat \<Rightarrow> nat \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> bool Heap"
  where [symmetric, int_folds]:
    "dbm_subset'_impl'_int = dbm_subset'_impl'"

schematic_goal dbm_subset'_impl'_int_code[code]:
  "dbm_subset'_impl'_int \<equiv> \<lambda>n m a b.
    do {
    l \<leftarrow> Array.len a;
    imp_for 0 l Heap_Monad.return
      (\<lambda>i _. do {
        x \<leftarrow> Array.nth a i; y \<leftarrow> Array.nth b i; Heap_Monad.return (dbm_le_int x y)
      })
      True
    }
"
  sorry

definition dbm_subset'_impl_int
  :: "nat \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> bool Heap"
  where [symmetric, int_folds]:
    "dbm_subset'_impl_int = dbm_subset'_impl"

schematic_goal dbm_subset'_impl_int_code[code]:
  "dbm_subset'_impl_int \<equiv> \<lambda>n a b.
    do {
    l \<leftarrow> Array.len a;
    imp_for 0 l Heap_Monad.return
      (\<lambda>i _. do {
        x \<leftarrow> Array.nth a i; y \<leftarrow> Array.nth b i; Heap_Monad.return (dbm_le_int x y)
      })
      True
    }
"
  sorry

definition dbm_subset_impl_int
  :: "nat \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> int DBMEntry Heap.array \<Rightarrow> bool Heap"
  where [symmetric, int_folds]:
    "dbm_subset_impl_int = dbm_subset_impl"

schematic_goal dbm_subset_impl_int_code[code]:
  "dbm_subset_impl_int \<equiv> ?i"
  unfolding dbm_subset_impl_int_def[symmetric] dbm_subset_impl_def
  unfolding int_folds
  .

lemmas [code_unfold] = int_folds


export_code state_space in SML module_name Test

hide_const Parser_Combinator.return
hide_const Error_Monad.return

definition
  "show_lit = String.implode o show"

definition "rename_state_space \<equiv> \<lambda>dc ids_to_names (broadcast, automata, bounds) L\<^sub>0 s\<^sub>0 formula.
  let _ = println (STR ''Make renaming'') in
  do {
    (m, num_states, num_actions, renum_acts, renum_vars, renum_clocks, renum_states,
      inv_renum_states, inv_renum_vars, inv_renum_clocks)
      \<leftarrow> make_renaming broadcast automata bounds;
    let _ = println (STR ''Renaming'');
    let (broadcast', automata', bounds') = rename_network
      broadcast bounds automata renum_acts renum_vars renum_clocks renum_states;
    let _ = println (STR ''Calculating ceiling'');
    let k = Simple_Network_Impl_nat_defs.local_ceiling broadcast' bounds' automata' m num_states;
    let _ = println (STR ''Running model checker'');
    let inv_renum_states' = (\<lambda>i. ids_to_names i o inv_renum_states i);
    let f = (\<lambda>show_clock
      show_state broadcast bounds' automata m num_states num_actions k L\<^sub>0 s\<^sub>0 formula.
      state_space broadcast bounds' automata m num_states num_actions k L\<^sub>0 s\<^sub>0 formula
        show_clock show_state ()
    );
    let r = do_rename_mc f dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
      m num_states num_actions renum_acts renum_vars renum_clocks renum_states
      inv_renum_states' inv_renum_vars inv_renum_clocks;
    let show_clock = show o inv_renum_clocks;
    let show_state = (show_state :: _ \<Rightarrow> _ \<Rightarrow> _ \<times> int list \<Rightarrow> _) inv_renum_states inv_renum_vars;
    let renamings =
      (m, num_states, num_actions, renum_acts, renum_vars, renum_clocks, renum_states,
       inv_renum_states, inv_renum_vars, inv_renum_clocks
      );
    Result (r, show_clock, show_state, renamings, k)
  }"

definition
  "check_subsumed n xs (i :: int) M \<equiv>
  do {
    (_, b) \<leftarrow> imp_nfoldli xs (\<lambda>(_, b). return (\<not> b)) (\<lambda>M' (j, b).
      if i = j then return (j + 1, b) else do {
        b \<leftarrow> dbm_subset'_impl n M M';
        if b then return (j, True) else return (j + 1, False)
      }
    ) (0, False);
    return b
  }
"

definition
  "imp_filter_index P xs = do {
  (_, xs) \<leftarrow> imp_nfoldli xs (\<lambda>_. return True) (\<lambda>x (i :: nat, xs).
    do {
      b \<leftarrow> P i x;
      return (i + 1, if b then (x # xs) else xs)
    }
  ) (0, []);
  return (rev xs)
  }"

definition
  "filter_dbm_list n xs =
    imp_filter_index (\<lambda>i M. do {b \<leftarrow> check_subsumed n xs i M; return (\<not> b)}) xs"

partial_function (heap) imp_map :: "('a \<Rightarrow> 'b Heap) \<Rightarrow> 'a list \<Rightarrow> 'b list Heap" where
  "imp_map f xs =
  (if xs = [] then return [] else do {y \<leftarrow> f (hd xs); ys \<leftarrow> imp_map f (tl xs); return (y # ys)})"

lemma imp_map_simps[code, simp]:
  "imp_map f [] = return []"
  "imp_map f (x # xs) = do {y \<leftarrow> f x; ys \<leftarrow> imp_map f xs; return (y # ys)}"
  by (simp add: imp_map.simps)+

definition trace_state where
  "trace_state n show_clock show_state \<equiv>
  \<lambda> (l, M). do {
      let st = show_state l;
      m \<leftarrow> show_dbm_impl n show_clock show M;
      let s = ''(''  @ st @ '', ['' @ m @ ''])''; 
      let s = String.implode s;
      let _ = println s;
      return ()
  }
" for show_clock show_state

definition
  "show_str = String.implode o show"

definition parse_convert_run_print where
  "parse_convert_run_print dc s \<equiv>
   case parse json s \<bind> convert of
     Error es \<Rightarrow> do {let _ = map println es; return ()}
   | Result (ids_to_names, _, broadcast, automata, bounds, formula, L\<^sub>0, s\<^sub>0) \<Rightarrow> do {
      let r = rename_state_space dc ids_to_names (broadcast, automata, bounds) L\<^sub>0 s\<^sub>0 formula;
      case r of
        Error es \<Rightarrow> do {let _ = map println es; return ()}
      | Result (r, show_clk, show_st, renamings, k) \<Rightarrow>
        case r of None \<Rightarrow> return () | Some r \<Rightarrow>
        do {
          r \<leftarrow> r;
          let _ = STR ''Number of discrete states: '' + (length r |> show_str) |> println;
          let _ =
            STR ''Size of passed list: '' + show_str (sum_list (map (length o snd) r)) |> println;
          let n = Simple_Network_Impl.clk_set' automata |> list_of_set |> length;
          r \<leftarrow> imp_map (\<lambda> (a, b). do {
              b \<leftarrow> imp_map (return o snd) b; b \<leftarrow> filter_dbm_list n b; return (a, b)
            }) r;
          let _ = STR ''Number of discrete states: '' + show_str (length r) |> println;
          let _ = STR ''Size of passed list after removing subsumed states: ''
            + show_str (sum_list (map (length o snd) r)) |> println;
          let show_dbm = (\<lambda>M. do {
            s \<leftarrow> show_dbm_impl_all n show_clk show M;
            return (''<'' @ s @ ''>'')
          });
          _ \<leftarrow> imp_map (\<lambda> (s, xs).
          do {
            let s = show_st s;
            xs \<leftarrow> imp_map show_dbm xs;
            let _ = s @ '': '' @ show xs |> String.implode |> println;
            return ()
          }
          ) r;
          return ()
        }
  }"

ML \<open>
structure Timing : sig
  val start_timer: unit -> unit
  val save_time: string -> unit
  val get_timings: unit -> (string * Time.time) list
end = struct
  val t = Unsynchronized.ref Time.zeroTime;
  val timings = Unsynchronized.ref [];
  fun start_timer () = (t := Time.now ());
  fun get_elapsed () = Time.- (Time.now (), !t);
  fun save_time s = (timings := ((s, get_elapsed ()) :: !timings));
  fun get_timings () = !timings;
end
\<close>

ML \<open>
fun print_timings () =
  let
    val tab = Timing.get_timings ();
    fun print_time (s, t) = writeln(s ^ ": " ^ Time.toString t);
  in map print_time tab end;
\<close>

code_printing
  constant "Show_State_Defs.tracei" \<rightharpoonup>
      (SML)   "(fn n => fn show_state => fn show_clock => fn typ => fn x => ()) _ _ _"
  and (OCaml) "(fun n show_state show_clock ty x -> ()) _ _ _"

datatype mode = Impl1 | Impl2 | Impl3

definition
  "distr xs \<equiv>
  let (m, d) =
  fold
    (\<lambda>x (m, d). case m x of None \<Rightarrow> (m(x \<mapsto> 1:: nat), x # d) | Some y \<Rightarrow> (m(x \<mapsto> (y + 1)), d))
    xs (Map.empty, [])
  in map (\<lambda>x. (x, the (m x))) (sort d)"

definition split_k'' :: "nat \<Rightarrow> ('a \<times> 'b list) list \<Rightarrow> ('a \<times> 'b list) list list" where
  "split_k'' k xs \<equiv> let
    width = sum_list (map (length o snd) xs) div k;
    width = (if length xs mod k = 0 then width else width + 1)
  in split_size (length o snd) width 0 [] xs"

definition
  "print_errors es = do {Heap_Monad.fold_map print_line_impl es; return ()}"

definition parse_convert_run_check where
  "parse_convert_run_check mode num_split dc s \<equiv>
   case parse json s \<bind> convert of
     Error es \<Rightarrow> print_errors es
   | Result (ids_to_names, _, broadcast, automata, bounds, formula, L\<^sub>0, s\<^sub>0) \<Rightarrow> do {
      let r = rename_state_space dc ids_to_names (broadcast, automata, bounds) L\<^sub>0 s\<^sub>0 formula;
      case r of
        Error es \<Rightarrow> print_errors es
      | Result (r, show_clk, show_st, renamings, k) \<Rightarrow>
        case r of None \<Rightarrow> return () | Some r \<Rightarrow> do {
        let t = now ();
        r \<leftarrow> r;
        let t = now () - t;
        print_line_impl
          (STR ''Time for model checking + certificate extraction: '' + time_to_string t);
        let (m,num_states,num_actions,renum_acts,renum_vars,renum_clocks,renum_states,
          inv_renum_states, inv_renum_vars, inv_renum_clocks
        ) = renamings;
        let _ = start_timer ();
        state_space \<leftarrow> Heap_Monad.fold_map (\<lambda>(s, xs).
          do {
            let xs = map snd xs;
            xs \<leftarrow> Heap_Monad.fold_map (dbm_to_list_impl m) xs;
            return (s, xs)
          }
        ) r;
        let _ = save_time STR ''Time for converting DBMs in certificate'';
        print_line_impl
          (STR ''Number of discrete states of state space: '' + show_lit (length state_space));
        let _ = STR ''Size of passed list: ''  + show_str (sum_list (map (length o snd) r))
          |> println;
        STR ''DBM list length distribution: '' + show_str (distr (map (length o snd) state_space))
          |> print_line_impl;
        let split =
          (if mode = Impl3 then split_k'' num_split state_space else split_k num_split state_space);
        let split_distr = map (sum_list o map (length o snd)) split;
        STR ''Size of passed list distribution after split: '' + show_str split_distr
          |> print_line_impl;
        let t = now ();
        check \<leftarrow> case mode of
          Impl1 \<Rightarrow> rename_check num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space
        | Impl2 \<Rightarrow> rename_check2 num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space |> return
        | Impl3 \<Rightarrow> rename_check3 num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space |> return;
        let t = now () - t;
        print_line_impl (STR ''Time for certificate checking: '' + time_to_string t);
        case check of
          Renaming_Failed \<Rightarrow> print_line_impl (STR ''Renaming failed'')
        | Preconds_Unsat \<Rightarrow> print_line_impl (STR ''Preconditions were not met'')
        | Sat \<Rightarrow> print_line_impl (STR ''Certificate was accepted'')
        | Unsat \<Rightarrow> print_line_impl (STR ''Certificate was rejected'')
        }
    }"

ML \<open>
  fun do_test dc file =
  let
    val s = file_to_string file;
  in
    @{code parse_convert_run_print} dc s end
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/HDDI_02.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/HDDI_02_test.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/simple.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/light_switch.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_test.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/bridge.muntax" ()
\<close>

ML_val \<open>
  do_test true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_mod1.muntax" ()
\<close>

code_printing
  constant "parallel_fold_map" \<rightharpoonup>
      (SML)   "(fn f => fn xs => fn () => Par'_List.map (fn x => f x ()) xs) _ _"

definition
  "num_split \<equiv> 4 :: nat"

ML \<open>
  fun do_check dc file =
  let
    val s = file_to_string file;
  in
    @{code parse_convert_run_check} @{code Impl3} @{code num_split} dc s end
\<close>

(*
ML_val \<open>
  do_check false "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/HDDI_02.muntax" ()
\<close>

ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/HDDI_02.muntax" ()
\<close>

ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/simple.muntax" ()
\<close>

ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/light_switch.muntax" ()
\<close>

ML_val \<open>
  do_check false "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_test.muntax" ()
\<close>

ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_test.muntax" ()
\<close>

ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/bridge.muntax" ()
\<close>
*)

ML_val \<open>
  do_check false "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_all_3.muntax" ()
\<close>

(*
ML_val \<open>
  do_check true "/Users/wimmers/Formalizations/Timed_Automata/benchmarks/PM_all_3.muntax" ()
\<close>
*)

text \<open>Executing \<open>Heap_Monad.fold_map\<close> in parallel in Isabelle/ML\<close>

definition
  \<open>Test \<equiv> Heap_Monad.fold_map (\<lambda>x. do {let _ = println STR ''x''; return x}) ([1,2,3] :: nat list)\<close>

ML_val \<open>@{code Test} ()\<close>


paragraph \<open>Checking external certificates\<close>

definition
  "list_of_json_object obj \<equiv>
  case obj of
    Object m \<Rightarrow> Result m
  | _ \<Rightarrow> Error [STR ''Not an object'']
"

definition
  "map_of_debug m \<equiv>
    let m = map_of m in
    (\<lambda>x.
      case m x of
        None \<Rightarrow> let _ = println (STR ''Key error: '' + show_lit x) in None
      | Some v \<Rightarrow> Some v)"

definition
  "renaming_of_json json \<equiv> do {
    vars \<leftarrow> list_of_json_object json;
    vars \<leftarrow> combine_map (\<lambda> (a, b). do {b \<leftarrow> of_nat b; Result (String.implode a, b)}) vars;
    Result (the o map_of_debug vars)
  }
  " for json

definition
  "nat_renaming_of_json max_id json \<equiv> do {
    vars \<leftarrow> list_of_json_object json;
    vars \<leftarrow> combine_map (\<lambda> (a, b). do {
      a \<leftarrow> parse lx_nat (String.implode a);
      b \<leftarrow> of_nat b;
      Result (a, b)
    }) vars;
    let ids = fst ` set vars;
    let missing = filter (\<lambda>i. i \<notin> ids) [0..<max_id];
    let m = the o map_of_debug vars;
    let m = extend_domain m missing (length vars);
    Result m
  }
  " for json

definition convert_renaming ::
  "(nat \<Rightarrow> nat \<Rightarrow> String.literal) \<Rightarrow> (String.literal \<Rightarrow> nat) \<Rightarrow> JSON \<Rightarrow> _" where
  "convert_renaming ids_to_names process_names_to_index json \<equiv> do {
    json \<leftarrow> of_object json;
    vars \<leftarrow> get json ''vars'';
    var_renaming \<leftarrow> renaming_of_json vars;
    clocks \<leftarrow> get json ''clocks'';
    clock_renaming \<leftarrow> renaming_of_json clocks;
    processes \<leftarrow> get json ''processes'';
    process_renaming \<leftarrow> renaming_of_json processes;
    locations \<leftarrow> get json ''locations'';
    locations \<leftarrow> list_of_json_object locations; \<comment>\<open>process name \<rightarrow> json\<close>
    locations \<leftarrow> combine_map (\<lambda> (name, renaming). do {
        let p_num = process_names_to_index (String.implode name);
        assert
          (process_renaming (String.implode name) = p_num)
          (STR ''Process renamings do not agree on '' + String.implode name);
        let max_id = 1000;
        renaming \<leftarrow> nat_renaming_of_json max_id renaming; \<comment>\<open>location id \<rightarrow> nat\<close>
        Result (p_num, renaming)
      }
      ) locations;
    let location_renaming = the o map_of locations; \<comment>\<open>process id \<rightarrow> location id \<rightarrow> nat\<close>
    Result (var_renaming, clock_renaming, location_renaming)
  }
  "
  for json

definition
  "load_renaming dc model renaming \<equiv>
  case
  do {
    model \<leftarrow> parse json model;
    renaming \<leftarrow> parse json renaming;
    (ids_to_names, process_names_to_index, broadcast, automata, bounds, formula, L\<^sub>0, s\<^sub>0)
      \<leftarrow> convert model;
    convert_renaming ids_to_names process_names_to_index renaming
  }
  of
    Error e \<Rightarrow> return (Error e)
  | Result r \<Rightarrow> do {
    let (var_renaming, clock_renaming, location_renaming) = r;
    let _ = map (\<lambda>p. map (\<lambda>n. location_renaming p n |> show_lit |> println) [0..<8]) [0..<6];
    return (Result ())
  }
"

ML \<open>
  fun do_check dc model_file renaming_file =
  let
    val model = file_to_string model_file;
    val renaming = file_to_string renaming_file;
  in
    @{code load_renaming} dc model renaming end
\<close>

ML_val \<open>
  do_check
    true
    "/Users/wimmers/Code/mlunta/benchmarks/resources/csma_R_6.muntax"
    "/Users/wimmers/Scratch/certificates/csma.renaming"
    ()
\<close>


definition convert_state_space :: "_ \<Rightarrow> ((nat list \<times> _) \<times> _) list" where
  "convert_state_space state_space \<equiv>
    map (\<lambda>((locs, vars), dbms). ((map nat locs, vars), dbms)) state_space"
  for state_space :: "((int list \<times> int list) \<times> int DBMEntry list list) list"

definition parse_convert_check1 where
  "parse_convert_check1 model renaming state_space \<equiv>
   do {
    model \<leftarrow> parse json model;
    (ids_to_names, process_names_to_index, broadcast, automata, bounds, formula, L\<^sub>0, s\<^sub>0)
      \<leftarrow> convert model;
    renaming \<leftarrow> parse json renaming;
    (var_renaming, clock_renaming, location_renaming) \<leftarrow>
        convert_renaming ids_to_names process_names_to_index renaming;
    let t = now ();
    let state_space = convert_state_space state_space;
    let t = now () - t;
    let _ = println (STR ''Time for converting state space: '' + time_to_string t);
    (m, num_states, num_actions, renum_acts, renum_vars, renum_clocks, renum_states,
      inv_renum_states, inv_renum_vars, inv_renum_clocks) \<leftarrow>
      make_renaming broadcast automata bounds;
    let renum_vars = var_renaming;
    let renum_clocks = clock_renaming;
    let renum_states = location_renaming;
    let _ = println (STR ''Renaming'');
    let (broadcast', automata', bounds') = rename_network
      broadcast bounds automata renum_acts renum_vars renum_clocks renum_states;
    let _ = println (STR ''Calculating ceiling'');
    let k = Simple_Network_Impl_nat_defs.local_ceiling broadcast' bounds' automata' m num_states;
    Result (broadcast, bounds, automata, k, L\<^sub>0, s\<^sub>0, formula,
          m, num_states, num_actions, renum_acts, renum_vars, renum_clocks, renum_states,
          state_space)
   }" for num_split and state_space :: "((int list \<times> int list) \<times> int DBMEntry list list) list"

definition parse_convert_check where
  "parse_convert_check mode num_split dc model renaming state_space \<equiv>
   let
     r = parse_convert_check1 model renaming state_space
   in case r of Error es \<Rightarrow> do {let _ = map println es; return ()}
   | Result r \<Rightarrow> do {
     let (broadcast, bounds, automata, k, L\<^sub>0, s\<^sub>0, formula,
          m, num_states, num_actions, renum_acts, renum_vars, renum_clocks, renum_states,
          state_space) = r;
        let _ = start_timer ();
        let _ = save_time STR ''Time for converting DBMs in certificate'';
        let _ = println (STR ''Number of discrete states: '' + show_lit (length state_space));
        let t = now ();
        check \<leftarrow> case mode of
          Impl1 \<Rightarrow> rename_check num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space
        | Impl2 \<Rightarrow> rename_check2 num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space |> return
        | Impl3 \<Rightarrow> rename_check3 num_split dc broadcast bounds automata k L\<^sub>0 s\<^sub>0 formula
            m num_states num_actions renum_acts renum_vars renum_clocks renum_states
            state_space |> return;
        let t = now () - t;
        let _ = println (STR ''Time for certificate checking: '' + time_to_string t);
        case check of
          Renaming_Failed \<Rightarrow> do {let _ = println STR ''Renaming failed''; return ()}
        | Preconds_Unsat \<Rightarrow> do {let _ = println STR ''Preconditions were not met''; return ()}
        | Sat \<Rightarrow> do {let _ = println STR ''Certificate was accepted''; return ()}
        | Unsat \<Rightarrow> do {let _ = println STR ''Certificate was rejected''; return ()}
    }
" for num_split and state_space :: "((int list \<times> int list) \<times> int DBMEntry list list) list"

(* XXX This is a bug fix. Fix in Isabelle distribution *)
code_printing
  constant IArray.length' \<rightharpoonup> (SML) "(IntInf.fromInt o Vector.length)"

code_printing
  constant Parallel.map \<rightharpoonup> (SML) "Par'_List.map"

lemma [code]: "run_map_heap f xs = Parallel.map (run_heap o f) xs"
  unfolding run_map_heap_def Parallel.map_def ..

code_printing code_module "Timing" \<rightharpoonup> (SML)
\<open>
structure Timing : sig
  val start_timer: unit -> unit
  val save_time: string -> unit
  val get_timings: unit -> (string * Time.time) list
  val set_cpu: bool -> unit
end = struct

  open Timer;

  val is_cpu = Unsynchronized.ref false;
  fun set_cpu b = is_cpu := b;

  val cpu_timer: cpu_timer option Unsynchronized.ref = Unsynchronized.ref NONE;
  val real_timer: real_timer option Unsynchronized.ref = Unsynchronized.ref NONE;

  val timings = Unsynchronized.ref [];
  fun start_timer () = (
    if !is_cpu then
      cpu_timer := SOME (startCPUTimer ())
    else
      real_timer := SOME (startRealTimer ()));
  fun get_elapsed () = (
    if !is_cpu then
      #usr (!cpu_timer |> the |> checkCPUTimer)
    else
      (!real_timer |> the |> checkRealTimer));
  fun save_time s = (timings := ((s, get_elapsed ()) :: !timings));
  fun get_timings () = !timings;
end
\<close>

paragraph \<open>Optimized code printings\<close>
(*
code_printing code_module "Iterators" \<rightharpoonup> (SML)
\<open>
fun imp_for i u c f s =
  let
    fun imp_for1 i u f s =
      if IntInf.<= (u, i) then (fn () => s)
      else if c s () then imp_for1 (IntInf.+ (i, 1)) u f (f (nat_of_integer i) s ())
      else (fn () => s)
  in imp_for1 (integer_of_nat i) (integer_of_nat u) f s end;

fun imp_fora i u f s =
  let
    fun imp_for1 i u f s =
      if IntInf.<= (u, i) then (fn () => s)
      else imp_for1 (IntInf.+ (i, 1)) u f (f (nat_of_integer i) s ())
  in imp_for1 (integer_of_nat i) (integer_of_nat u) f s end;
\<close>
*)
term nat_of_integer
term integer_of_nat

code_thms imp_for

partial_function (heap) imp_for_int :: "integer \<Rightarrow> integer \<Rightarrow> ('a \<Rightarrow> bool Heap) \<Rightarrow> (integer \<Rightarrow> 'a \<Rightarrow> 'a Heap) \<Rightarrow> 'a \<Rightarrow> 'a Heap" where
  "imp_for_int i u c f s = (if i \<ge> u then return s else do {ctn <- c s; if ctn then f i s \<bind> imp_for_int (i + 1) u c f else return s})"

lemma imp_for_imp_for_int[code_unfold]:
  "imp_for i u c f s \<equiv> imp_for_int (integer_of_nat i) (integer_of_nat u) c (f o nat_of_integer) s"
  apply (induction "u - i" arbitrary: i u s)
  apply (simp add: imp_for_int)
  apply (simp; fail)
  apply simp
  apply (fo_rule arg_cong)
  by auto

partial_function (heap) imp_for'_int :: "integer \<Rightarrow> integer \<Rightarrow> (integer \<Rightarrow> 'a \<Rightarrow> 'a Heap) \<Rightarrow> 'a \<Rightarrow> 'a Heap" where
  "imp_for'_int i u f s = (if i \<ge> u then return s else f i s \<bind> imp_for'_int (i + 1) u f)"

lemma imp_for'_imp_for_int[code_unfold]:
  "imp_for' i u f s \<equiv> imp_for'_int (integer_of_nat i) (integer_of_nat u) (f o nat_of_integer) s"
  thm imp_for'.simps
  sorry

lemmas [code] =
  imp_for_int.simps
  imp_for'_int.simps

(*
code_printing
  constant imp_for \<rightharpoonup> (SML) "imp'_for"
| constant imp_for' \<rightharpoonup> (SML) "imp'_fora"
*)

export_code parse_convert_check parse_convert_run_print parse_convert_run_check Result Error
  nat_of_integer int_of_integer DBMEntry.Le DBMEntry.Lt DBMEntry.INF
  Impl1 Impl2 Impl3
  E_op_impl
  in SML module_name Model_Checker file "../ML/Certificate.sml"

code_printing code_module "Printing" \<rightharpoonup> (Haskell)
\<open>
import qualified Debug.Trace;

print s = Debug.Trace.trace s ();

printM s = Debug.Trace.traceM s;
\<close>

code_printing
  constant Printing.print \<rightharpoonup> (Haskell) "Printing.print _"
(* 
code_printing code_module "Timing" \<rightharpoonup> (Haskell)
\<open>
import Data.Time.Clock.System;

now = systemToTAITime . Prelude.unsafePerformIO getSystemTime;
\<close>
 *)

code_printing
  constant print_line_impl \<rightharpoonup> (Haskell) "Printing.printM _"

(* code_printing
  constant "now" \<rightharpoonup> (Haskell) "Prelude.const (Time (Int'_of'_integer 0)) _"

code_printing
  constant "time_to_string" \<rightharpoonup> (Haskell) "Prelude.show _"

code_printing
  constant "(-) :: time \<Rightarrow> time \<Rightarrow> time" \<rightharpoonup> (Haskell)
    "(case _ of Time a -> case _ of Time b -> Time (b - a))" *)

code_printing
  type_constructor time \<rightharpoonup> (Haskell) "Integer"
  | constant "now" \<rightharpoonup> (Haskell) "Prelude.const 0"
  | constant "time_to_string" \<rightharpoonup> (Haskell) "Prelude.show _"
  | constant "(-) :: time \<Rightarrow> time \<Rightarrow> time" \<rightharpoonup> (Haskell) "(-)"

code_printing
  constant list_of_set' \<rightharpoonup> (Haskell) "(case _ of Set xs -> xs)"

export_code parse_convert_check parse_convert_run_print parse_convert_run_check Result Error
  nat_of_integer int_of_integer DBMEntry.Le DBMEntry.Lt DBMEntry.INF
  Impl1 Impl2 Impl3 in Haskell module_name Model_Checker file "../Haskell/"

end
