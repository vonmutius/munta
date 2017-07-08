theory Subsumption_Graphs
  imports Simulation_Graphs
begin

chapter \<open>Subsumption Graphs\<close>

section \<open>Preliminaries\<close>

subsection \<open>Graphs\<close>

context Graph_Defs
begin

lemma steps_non_empty[simp]:
  "\<not> steps []"
  by (auto elim: steps.cases)

lemma steps_replicate:
  "steps (hd xs # concat (replicate n (tl xs)))" if "last xs = hd xs" "steps xs" "n > 0"
  using that
proof (induction n)
  case 0
  then show ?case by simp
next
  case (Suc n)
  show ?case
  proof (cases n)
    case 0
    with Suc.prems show ?thesis by (cases xs; auto)
  next
    case prems: (Suc nat)
    from Suc.prems have [simp]: "hd xs # tl xs @ ys = xs @ ys" for ys
      by (cases xs; auto)
    from Suc.prems have **: "tl xs @ ys = tl (xs @ ys)" for ys
      by (cases xs; auto)
    from prems Suc show ?thesis
      by - (simp; simp add: **; rule steps_append; cases xs; auto)
  qed
qed

lemma steps_ConsD:
  "steps xs" if "steps (x # xs)" "xs \<noteq> []"
  using that by (auto elim: steps.cases)

lemma steps_appendD1:
  "steps xs" if "steps (xs @ ys)" "xs \<noteq> []"
  using that proof (induction xs)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  then show ?case
    by - (cases xs; auto elim: steps.cases)
qed

lemma steps_appendD2:
  "steps ys" if "steps (xs @ ys)" "ys \<noteq> []"
  using that by (induction xs) (auto elim: steps.cases)

lemmas (in Graph_Defs) stepsD = steps_ConsD steps_appendD1 steps_appendD2

end (* Graph Defs *)


locale Graph_Start_Defs = Graph_Defs +
  fixes s\<^sub>0 :: 'a
begin

definition reachable where
  "reachable = C\<^sup>*\<^sup>* s\<^sub>0"

lemma start_reachable[intro!, simp]:
  "reachable s\<^sub>0"
  unfolding reachable_def by auto

lemma reachable_step[intro]:
  "reachable b" if "reachable a" "C a b"
  using that unfolding reachable_def by auto

lemma reachable_steps_append:
  assumes "reachable a" "steps xs" "hd xs = a" "last xs = b"
  shows "reachable b"
  using assms unfolding reachable_def
  by (induction xs arbitrary: a; force intro: rtranclp.rtrancl_into_rtrancl elim: steps.cases)

lemmas steps_reachable = reachable_steps_append[of s\<^sub>0, simplified]

lemma reachable_steps_elem:
  "reachable y" if "reachable x" "steps xs" "y \<in> set xs" "hd xs = x"
proof -
  from \<open>y \<in> set xs\<close> obtain as bs where [simp]: "xs = as @ y # bs"
    by (auto simp: in_set_conv_decomp)
  show ?thesis
  proof (cases "as = []")
    case True
    with that show ?thesis
      by simp
  next
    case False
    with steps_appendD1[of \<open>as @ [y]\<close> bs] \<open>steps xs\<close> have "steps (as @ [y])"
      by simp
    with \<open>as \<noteq> []\<close> \<open>hd xs = x\<close> \<open>reachable x\<close> show ?thesis
      by (auto intro: reachable_steps_append)
  qed
qed

lemma reachable_steps:
  "\<exists> xs. steps xs \<and> hd xs = s\<^sub>0 \<and> last xs = x" if "reachable x"
  using that unfolding reachable_def
proof induction
  case base
  then show ?case by (inst_existentials "[s\<^sub>0]"; force)
next
  case (step y z)
  from step.IH guess xs by clarify
  with step.hyps show ?case
    apply (inst_existentials "xs @ [z]")
    apply (force intro: steps_append_single)
    by (cases xs; auto)+
qed

lemma reachable_cycle_iff:
  "(\<exists> ws. steps (s\<^sub>0 # ws @ [x] @ xs @ [x])) \<longleftrightarrow> reachable x \<and> steps ([x] @ xs @ [x])"
proof (safe, goal_cases)
  case (1 ws)
  then have "steps ((s\<^sub>0 # ws @ [x]) @ (xs @ [x]))"
    by simp
  then have "steps (s\<^sub>0 # ws @ [x])"
    by (blast dest: stepsD)
  then show ?case
    by (auto intro: steps_reachable stepsD)
next
  case (2 ws)
  then show ?case by (auto dest: stepsD)
next
  case prems: 3
  show ?case
  proof (cases "s\<^sub>0 = x")
    case True
    with prems show ?thesis
      by (inst_existentials xs) (frule steps_append, assumption, auto)
  next
    case False
    from reachable_steps[OF \<open>reachable x\<close>] obtain ws where
      "steps ws" "hd ws = s\<^sub>0" "last ws = x"
      by auto
    with \<open>_ \<noteq> x\<close> obtain us where "ws = s\<^sub>0 # us @ [x]"
      apply atomize_elim
      apply (cases ws)
       apply (simp; fail)
      subgoal for a ws'
        by (inst_existentials "butlast ws'") auto
      done
    with \<open>steps ws\<close> prems show ?thesis
      by (inst_existentials us) (drule steps_append, assumption, auto)
  qed
qed

end (* Graph Start Defs *)


subsection \<open>Lists\<close>

lemma sublist_split:
  "sublist xs (A \<union> B) = sublist xs A @ sublist xs B" if "\<forall> i \<in> A. \<forall> j \<in> B. i < j"
  using that
  proof (induction xs arbitrary: A B)
    case Nil
    then show ?case by simp
  next
    case (Cons a xs)
    let ?A = "{j. Suc j \<in> A}" and ?B = "{j. Suc j \<in> B}"
    from Cons.prems have *: "\<forall>i\<in>?A. \<forall>a\<in>?B. i < a"
      by auto
    have [simp]: "{j. Suc j \<in> A \<or> Suc j \<in> B} = ?A \<union> ?B"
      by auto
    show ?case
      unfolding sublist_Cons
    proof (clarsimp, safe, goal_cases)
      case 2
      with Cons.prems have "A = {}"
        by auto
      with Cons.IH[OF *] show ?case by auto
    qed (use Cons.prems Cons.IH[OF *] in auto)
  qed

lemma sublist_nth:
  "sublist xs {i} = [xs ! i]" if "i < length xs"
  using that
  proof (induction xs arbitrary: i)
    case Nil
    then show ?case by simp
  next
    case (Cons a xs)
    then show ?case
      by (cases i) (auto simp: sublist_Cons)
  qed

lemma sublist_shift:
  "sublist (xs @ ys) S = sublist ys {x - length xs | x. x \<in> S}" if
  "\<forall> i \<in> S. length xs \<le> i"
  using that
proof (induction xs arbitrary: S)
  case Nil
  then show ?case by auto
next
  case (Cons a xs)
  have [simp]: "{x - length xs |x. Suc x \<in> S} = {x - Suc (length xs) |x. x \<in> S}" if "0 \<notin> S"
    using that apply safe
     apply force
    subgoal for x x'
      by (cases x') auto
    done
  from Cons.prems show ?case
    by (simp, subst sublist_Cons, subst Cons.IH; auto)
qed

lemma filter_eq_appendD:
  "\<exists> xs' ys'. filter P xs' = xs \<and> filter P ys' = ys \<and> as = xs' @ ys'" if "filter P as = xs @ ys"
  using that
proof (induction xs arbitrary: as)
  case Nil
  then show ?case
    by (inst_existentials "[] :: 'a list" as) auto
next
  case (Cons a xs)
  from filter_eq_ConsD[OF Cons.prems[simplified]] obtain us vs where
    "as = us @ a # vs" "\<forall>u\<in>set us. \<not> P u" "P a" "filter P vs = xs @ ys"
    by auto
  moreover from Cons.IH[OF \<open>_ = xs @ ys\<close>] obtain xs' ys where
    "filter P xs' = xs" "vs = xs' @ ys"
    by auto
  ultimately show ?case
    by (inst_existentials "us @ [a] @ xs'" ys) auto
qed

lemma list_all2_elem_filter:
  assumes "list_all2 P xs us" "x \<in> set xs"
  shows "length (filter (P x) us) \<ge> 1"
  using assms by (induction xs arbitrary: us) (auto simp: list_all2_Cons1)

lemma list_all2_replicate_elem_filter:
  assumes "list_all2 P (concat (replicate n xs)) ys" "x \<in> set xs"
  shows "length (filter (P x) ys) \<ge> n"
  using assms
  by (induction n arbitrary: ys; fastforce dest: list_all2_elem_filter simp: list_all2_append1)

lemma sublist_eq_ConsD:
  assumes "sublist xs I = x # as"
  shows
    "\<exists> ys zs.
      xs = ys @ x # zs \<and> length ys \<in> I \<and> (\<forall> i \<in> I. i \<ge> length ys)
      \<and> sublist zs ({i - length ys - 1 | i. i \<in> I \<and> i > length ys}) = as"
  using assms
proof (induction xs arbitrary: I x as)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  from Cons.prems show ?case
    unfolding sublist_Cons
    apply (auto split: if_split_asm)
    subgoal
      by (inst_existentials "[] :: 'a list" xs; force intro: arg_cong2[of xs xs _ _ sublist])
    subgoal
      apply (drule Cons.IH)
      apply safe
      subgoal for ys zs
        apply (inst_existentials "a # ys" zs)
           apply simp+
         apply standard
        subgoal for i
          by (cases i; auto)
        apply (rule arg_cong2[of zs zs _ _ sublist])
         apply simp
        apply safe
        subgoal for _ i
          by (cases i; auto)
        by force
      done
    done
qed

lemma sublist_out_of_bounds:
  "sublist xs I = []" if "\<forall>i \<in> I. i \<ge> length xs"
  using that
  (* Found by sledgehammer *)
proof -
  have
    "\<forall>N as.
      (\<exists>n. n \<in> N \<and> \<not> length (as::'a list) \<le> n)
      \<or> (\<forall>asa. sublist (as @ asa) N = sublist asa {n - length as |n. n \<in> N})"
    using sublist_shift by blast
  then obtain nn :: "nat set \<Rightarrow> 'a list \<Rightarrow> nat" where
    "\<forall>N as.
      nn N as \<in> N \<and> \<not> length as \<le> nn N as
    \<or> (\<forall>asa. sublist (as @ asa) N = sublist asa {n - length as |n. n \<in> N})"
    by moura
  then have
    "\<And>as. sublist as {n - length xs |n. n \<in> I} = sublist (xs @ as) I
      \<or> sublist (xs @ []) I = []"
    using that by fastforce
  then have "sublist (xs @ []) I = []"
    by (metis (no_types) sublist_nil)
  then show ?thesis
    by simp
qed

lemma sublist_eq_appendD:
  assumes "sublist xs I = as @ bs"
  shows
    "\<exists> ys zs.
        xs = ys @ zs \<and> sublist ys I = as
        \<and> sublist zs {i - length ys | i. i \<in> I \<and> i \<ge> length ys} = bs"
  using assms
proof (induction as arbitrary: xs I)
  case Nil
  then show ?case
    by (inst_existentials "[] :: 'a list" "sublist bs") auto
next
  case (Cons a ys xs)
  from sublist_eq_ConsD[of xs I a "ys @ bs"] Cons.prems obtain ys' zs' where
    "xs = ys' @ a # zs'" "length ys' \<in> I" "\<forall>i \<in> I. i \<ge> length ys'"
    "sublist zs' {i - length ys' - 1 |i. i \<in> I \<and> i > length ys'} = ys @ bs"
    by auto
  moreover from Cons.IH[OF \<open>sublist zs' _ = _\<close>] guess ys'' zs'' by clarify
  ultimately show ?case
    apply (inst_existentials "ys' @ a # ys''" zs'')
      apply (simp; fail)
    subgoal
      by (simp add: sublist_out_of_bounds sublist_append sublist_Cons)
        (rule arg_cong2[of ys'' ys'' _ _ sublist]; force)
    subgoal
      by safe (rule arg_cong2[of zs'' zs'' _ _ sublist]; force) (* Slow *)
    done
qed

lemma filter_sublist_length:
  "length (filter P (sublist xs I)) \<le> length (filter P xs)"
proof (induction xs arbitrary: I)
  case Nil
  then show ?case
    by simp
next
  case Cons
  then show ?case
  (* Found by sledgehammer *)
  proof -
    fix a :: 'a and xsa :: "'a list" and Ia :: "nat set"
    assume a1: "\<And>I. length (filter P (sublist xsa I)) \<le> length (filter P xsa)"
    have f2:
      "\<forall>b bs N. if 0 \<in> N then sublist ((b::'a) # bs) N =
        [b] @ sublist bs {n. Suc n \<in> N} else sublist (b # bs) N = [] @ sublist bs {n. Suc n \<in> N}"
      by (simp add: sublist_Cons)
    have f3:
      "sublist (a # xsa) Ia = [] @ sublist xsa {n. Suc n \<in> Ia}
        \<longrightarrow> length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P xsa)"
      using a1 by (metis append_Nil)
    have f4: "length (filter P (sublist xsa {n. Suc n \<in> Ia})) + 0 \<le> length (filter P xsa) + 0"
      using a1 by simp
    have f5:
      "Suc (length (filter P (sublist xsa {n. Suc n \<in> Ia})) + 0)
      = length (a # filter P (sublist xsa {n. Suc n \<in> Ia}))"
      by force
    have f6: "Suc (length (filter P xsa) + 0) = length (a # filter P xsa)"
      by simp
    { assume "\<not> length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P (a # xsa))"
      { assume "sublist (a # xsa) Ia \<noteq> [a] @ sublist xsa {n. Suc n \<in> Ia}"
        moreover
        { assume
            "sublist (a # xsa) Ia = [] @ sublist xsa {n. Suc n \<in> Ia}
            \<and> length (filter P (a # xsa)) \<le> length (filter P xsa)"
          then have "length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P (a # xsa))"
            using a1 by (metis (no_types) append_Nil filter.simps(2) impossible_Cons) }
        ultimately have "length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P (a # xsa))"
          using f3 f2 by (meson dual_order.trans le_cases) }
      then have "length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P (a # xsa))"
        using f6 f5 f4 a1 by (metis Suc_le_mono append_Cons append_Nil filter.simps(2)) }
    then show "length (filter P (sublist (a # xsa) Ia)) \<le> length (filter P (a # xsa))"
      by meson
  qed
qed


subsection \<open>Transitive Closure\<close>

(* XXX Move *)
lemma rtranclp_ev_induct[consumes 1, case_names irrefl trans step]:
  fixes P :: "'a \<Rightarrow> bool" and R :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
  assumes reachable_finite: "finite {x. R\<^sup>*\<^sup>* a x}"
  assumes R_irrefl: "\<And> x. \<not> R x x" and R_trans[intro]: "\<And> x y z. R x y \<Longrightarrow> R y z \<Longrightarrow> R x z"
  assumes step: "\<And> x. R\<^sup>*\<^sup>* a x \<Longrightarrow> P x \<or> (\<exists> y. R x y)"
  shows "\<exists> x. P x \<and> R\<^sup>*\<^sup>* a x"
proof -
  (* XXX Lemma *)
  have trans_1: "R a c" if "R a b" "R\<^sup>*\<^sup>* b c" for a b c
    using that(2,1) by induction auto
  (* XXX Lemma *)
  have trans_2: "R a c" if "R\<^sup>*\<^sup>* a b" "R b c" for a b c
    using that by induction auto
  let ?S = "{y. R\<^sup>*\<^sup>* a y}"
  from reachable_finite have "finite ?S"
    by auto
  then have "\<exists> x \<in> ?S. P x"
    using step
  proof (induction ?S arbitrary: a rule: finite_psubset_induct)
    case psubset
    let ?S = "{y. R\<^sup>*\<^sup>* a y}"
    from psubset have "finite ?S" by auto
    show ?case
    proof (cases "?S = {}")
      case True
      then show ?thesis by auto
    next
      case False
      then obtain y where "R\<^sup>*\<^sup>* a y"
        by auto
      from psubset(3)[OF this] show ?thesis
      proof
        assume "P y"
        with \<open>R\<^sup>*\<^sup>* a y\<close> show ?thesis by auto
      next
        assume "\<exists> z. R y z"
        then obtain z where "R y z" by safe
        let ?T = "{y. R\<^sup>*\<^sup>* z y}"
        from \<open>R y z\<close> \<open>R\<^sup>*\<^sup>* a y\<close> have "\<not> R\<^sup>*\<^sup>* z a"
          by (auto simp: R_irrefl dest: trans_1 trans_2)
        then have "a \<notin> ?T" by auto
        moreover have "?T \<subseteq> ?S"
          using \<open>R\<^sup>*\<^sup>* a y\<close> \<open>R y z\<close> by auto
        ultimately have "?T \<subset> ?S"
          by auto
        have "P x \<or> Ex (R x)" if "R\<^sup>*\<^sup>* z x" for x
          using that \<open>R y z\<close> \<open>R\<^sup>*\<^sup>* a y\<close> by (auto intro!: psubset.prems)
        from psubset.hyps(2)[OF \<open>?T \<subset> ?S\<close> this] psubset.prems \<open>R y z\<close> \<open>R\<^sup>*\<^sup>* a y\<close> obtain w
          where "R\<^sup>*\<^sup>* z w" "P w" by auto
        with \<open>R\<^sup>*\<^sup>* a y\<close> \<open>R y z\<close> have "R\<^sup>*\<^sup>* a w" by auto
        with \<open>P w\<close> show ?thesis by auto
      qed
    qed
  qed
  then show ?thesis by auto
qed

(* XXX Move *)
lemma rtranclp_ev_induct2[consumes 2, case_names irrefl trans step]:
  fixes P Q :: "'a \<Rightarrow> bool" and R :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
  assumes Q_finite: "finite {x. Q x}" and Q_witness: "Q a"
  assumes R_irrefl: "\<And> x. \<not> R x x" and R_trans[intro]: "\<And> x y z. R x y \<Longrightarrow> R y z \<Longrightarrow> R x z"
  assumes step: "\<And> x. Q x \<Longrightarrow> P x \<or> (\<exists> y. R x y \<and> Q y)"
  shows "\<exists> x. P x \<and> Q x \<and> R\<^sup>*\<^sup>* a x"
proof -
  let ?R = "\<lambda> x y. R x y \<and> Q x \<and> Q y"
  have [intro]: "R\<^sup>*\<^sup>* a x" if "?R\<^sup>*\<^sup>* a x" for x
    using that by induction auto
  have [intro]: "Q x" if "?R\<^sup>*\<^sup>* a x" for x
    using that \<open>Q a\<close> by (auto elim: rtranclp.cases)
  have "{x. ?R\<^sup>*\<^sup>* a x} \<subseteq> {x. Q x}" by auto
  with \<open>finite _\<close> have "finite {x. ?R\<^sup>*\<^sup>* a x}" by - (rule finite_subset)
  then have "\<exists>x. P x \<and> ?R\<^sup>*\<^sup>* a x"
  proof (induction rule: rtranclp_ev_induct)
    case prems: (step x)
    with step[of x] show ?case by auto
  qed (auto simp: R_irrefl)
  then show ?thesis by auto
qed


section \<open>Definitions\<close>

subsection \<open>Orders\<close>

locale Order_Defs =
  fixes less_eq :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<preceq>" 50)
begin

(* XXX Clean *)
no_notation dbm_le ("_ \<preceq> _" [51, 51] 50)
no_notation dbm_lt ("_ \<prec> _" [51, 51] 50)

definition less (infix "\<prec>" 50) where
  "a \<prec> b \<equiv> a \<noteq> b \<and> a \<preceq> b"

lemma less_irrefl[intro, simp]:
  "\<not> x \<prec> x"
  unfolding less_def by auto

lemma subsumes_strictly_subsumesI[intro]:
  "a \<preceq> b" if "a \<prec> b"
  using that unfolding less_def by auto

end (* Order Defs *)


locale Pre_Order = Order_Defs +
  assumes refl[intro!, simp]:  "a \<preceq> a"
      and trans[trans, intro]: "a \<preceq> b \<Longrightarrow> b \<preceq> c \<Longrightarrow> a \<preceq> c"

locale Partial_Order = Pre_Order +
  assumes antisym[simp]: "a \<preceq> b \<Longrightarrow> b \<preceq> a \<Longrightarrow> a = b"
begin

(* XXX *)
sublocale order "op \<preceq>" "op \<prec>"
  by standard (auto simp: less_def)

lemma less_trans[intro, trans]:
  "x \<prec> z" if "x \<prec> y" "y \<prec> z" for x y z
  using that unfolding less_def by auto

end (* Partial Order *)


subsection \<open>Definitions Subsumption Graphs\<close>

locale Subsumption_Graph_Pre_Defs = Order_Defs +
  fixes E ::  "'a \<Rightarrow> 'a \<Rightarrow> bool" -- \<open>The full edge set\<close>
    and s\<^sub>0 :: 'a                 -- \<open>Start state\<close>
begin

sublocale Graph_Start_Defs E s\<^sub>0 .

end

(* XXX Merge with Worklist locales *)
locale Subsumption_Graph_Defs = Subsumption_Graph_Pre_Defs +
  fixes RE :: "'a \<Rightarrow> 'a \<Rightarrow> bool" -- \<open>Subgraph of the graph given by the full edge set\<close>
begin

sublocale G: Graph_Start_Defs RE s\<^sub>0 .

sublocale G': Graph_Start_Defs "\<lambda> x y. RE x y \<or> (x \<prec> y \<and> RE\<^sup>*\<^sup>* s\<^sub>0 y)" s\<^sub>0 .

sublocale G'': Graph_Start_Defs "\<lambda> x y. RE x y \<or> (x \<preceq> y \<and> E\<^sup>*\<^sup>* s\<^sub>0 y)" s\<^sub>0 .

end (* Subsumption Graph Defs *)


locale Subsumption_Graph_Pre = Subsumption_Graph_Pre_Defs + Partial_Order +
  assumes mono:
    "a \<preceq> b \<Longrightarrow> E a a' \<Longrightarrow> reachable a \<Longrightarrow> reachable b \<Longrightarrow> \<exists> b'. E b b' \<and> a' \<preceq> b'"

locale Reachability_Compatible_Subsumption_Graph = Subsumption_Graph_Defs + Subsumption_Graph_Pre +
  assumes reachability_compatible:
    "\<forall> s. G.reachable s \<longrightarrow> (\<forall> s'. E s s' \<longrightarrow> RE s s') \<or> (\<exists> t. s \<prec> t \<and> G.reachable t)"
  assumes subgraph: "\<forall> s s'. RE s s' \<longrightarrow> E s s'"
  assumes finite_reachable: "finite {a. G.reachable a}"

locale Subsumption_Graph_View_Defs = Subsumption_Graph_Defs +
  fixes SE ::  "'a \<Rightarrow> 'a \<Rightarrow> bool" -- \<open>Subsumption edges\<close>
    and covered :: "'a \<Rightarrow> bool"

locale Reachability_Compatible_Subsumption_Graph_View =
  Subsumption_Graph_View_Defs + Subsumption_Graph_Pre +
  assumes reachability_compatible:
    "\<forall> s. G.reachable s \<longrightarrow>
      (if covered s then (\<exists> t. SE s t \<and> G.reachable t) else (\<forall> s'. E s s' \<longrightarrow> RE s s'))"
  assumes subsumption: "\<forall> s'. SE s s' \<longrightarrow> s \<prec> s'"
  assumes subgraph: "\<forall> s s'. RE s s' \<longrightarrow> E s s'"
  assumes finite_reachable: "finite {a. G.reachable a}"
begin

sublocale Reachability_Compatible_Subsumption_Graph
proof standard
  have "(\<forall>s'. E s s' \<longrightarrow> RE s s') \<or> (\<exists>t. s \<prec> t \<and> G.reachable t)" if "G.reachable s" for s
    using that reachability_compatible subsumption by (cases "covered s"; fastforce)
  then show "\<forall>s. G.reachable s \<longrightarrow> (\<forall>s'. E s s' \<longrightarrow> RE s s') \<or> (\<exists>t. s \<prec> t \<and> G.reachable t)"
    by auto
qed (use subgraph in \<open>auto intro: finite_reachable mono\<close>)

end (* Reachability Compatible Subsumption Graph View *)

locale Reachability_Compatible_Subsumption_Graph_Final = Reachability_Compatible_Subsumption_Graph +
  fixes F :: "'a \<Rightarrow> bool" -- \<open>Final states\<close>
  assumes F_mono[intro]: "F a \<Longrightarrow> a \<preceq> b \<Longrightarrow> F b"

locale Liveness_Compatible_Subsumption_Graph = Reachability_Compatible_Subsumption_Graph_Final +
  assumes no_subsumption_cycle:
    "G'.reachable x \<Longrightarrow> G'.steps (x # xs @ [x]) \<Longrightarrow> G.steps (x # xs @ [x])"

section \<open>Reachability\<close>

context Subsumption_Graph_Pre
begin

lemma steps_mono:
  assumes "steps (x # xs)" "x \<preceq> y" "reachable x" "reachable y"
  shows "\<exists> ys. steps (y # ys) \<and> list_all2 (op \<preceq>) xs ys"
  using assms
proof (induction "x # xs" arbitrary: x y xs)
  case (Single x)
  then show ?case by auto
next
  case (Cons x y xs x')
  from mono[OF \<open>x \<preceq> x'\<close> \<open>E x y\<close>] Cons.prems obtain y' where "E x' y'" "y \<preceq> y'"
    by auto
  with Cons.hyps(3)[OF \<open>y \<preceq> y'\<close>] \<open>E x y\<close> Cons.prems obtain ys where
    "steps (y' # ys)" "list_all2 op \<preceq> xs ys"
    by auto
  with \<open>E x' y'\<close> \<open>y \<preceq> y'\<close> show ?case
    by auto
qed

end (* Subsumption Graph Pre *)

context Reachability_Compatible_Subsumption_Graph
begin

lemma subgraph'[intro]:
  "E s s'" if "RE s s'"
  using that subgraph by blast

lemma G_reachability_sound[intro]:
  "reachable a" if "G.reachable a"
  using that unfolding reachable_def G.reachable_def by (induction; blast intro: rtranclp.intros(2))

lemma G_steps_sound[intro]:
  "steps xs" if "G.steps xs"
  using that by induction auto

lemma G_run_sound[intro]:
  "run xs" if "G.run xs"
  using that by (coinduction arbitrary: xs) (auto 4 3 elim: G.run.cases)

lemma reachable_has_surrogate:
  "\<exists> t. G.reachable t \<and> s \<preceq> t \<and> (\<forall> s'. E t s' \<longrightarrow> RE t s')" if "G.reachable s"
  using that
proof -
  from finite_reachable \<open>G.reachable s\<close> obtain x where
    "\<forall>s'. E x s' \<longrightarrow> RE x s'" "G.reachable x" "op \<prec>\<^sup>*\<^sup>* s x"
    apply atomize_elim
    apply (induction rule: rtranclp_ev_induct2)
    using reachability_compatible by auto
  moreover from \<open>op \<prec>\<^sup>*\<^sup>* s x\<close> have "s \<prec> x \<or> s = x"
    by induction auto
  ultimately show ?thesis by auto
qed

lemma G'_reachability_sound[intro]:
  "reachable a" if "G'.reachable a"
  using that unfolding G'.reachable_def reachable_def
  by (induction;
      blast intro: rtranclp.intros(2) G_reachability_sound[unfolded reachable_def G.reachable_def])

lemma G'_reachable_G_reachable[intro]:
  "G.reachable a" if "G'.reachable a"
  using that unfolding G'.reachable_def G.reachable_def
  by (induction; blast intro: rtranclp.intros(2))

lemma G'_finite_reachable: "finite {a. G'.reachable a}"
  by (blast intro: finite_subset[OF _ finite_reachable])

lemma G_reachable_G'_reachable[intro]:
  "G'.reachable a" if "G.reachable a"
  using that unfolding G'.reachable_def G.reachable_def
  by (induction; blast intro: rtranclp.intros(2))

lemma reachable_has_surrogate':
  "\<exists> t xs. G'.steps xs \<and> xs \<noteq> [] \<and> hd xs = s \<and> last xs = t \<and> s \<preceq> t \<and> (\<forall> s'. E t s' \<longrightarrow> RE t s')"
  if "G.reachable s"
proof -
  from \<open>G.reachable s\<close> have \<open>G.reachable s\<close> by auto
  from finite_reachable this obtain x where
    real_edges: "\<forall>s'. E x s' \<longrightarrow> RE x s'" and "G.reachable x" "op \<prec>\<^sup>*\<^sup>* s x"
    apply atomize_elim
    apply (induction rule: rtranclp_ev_induct2)
    using reachability_compatible by auto
  from \<open>op \<prec>\<^sup>*\<^sup>* s x\<close> have "s \<prec> x \<or> s = x"
    by induction auto
  then show ?thesis
  proof
    assume "s \<prec> x"
    with real_edges \<open>G.reachable x\<close> show ?thesis
      by (inst_existentials "x" "[s,x]") (auto simp: G.reachable_def)
  next
    assume "s = x"
    with real_edges show ?thesis
      by (inst_existentials "s" "[s]") auto
  qed
qed

lemma reachable_has_surrogate'':
  "\<exists> t. G.reachable t \<and> s \<preceq> t \<and> (\<forall> s'. E t s' \<longrightarrow> RE t s')" if "G'.reachable s"
proof -
  from \<open>G'.reachable s\<close> have \<open>G.reachable s\<close> by auto
  from finite_reachable this obtain x where
    "\<forall>s'. E x s' \<longrightarrow> RE x s'" "G.reachable x" "op \<prec>\<^sup>*\<^sup>* s x"
    apply atomize_elim
    apply (induction rule: rtranclp_ev_induct2)
    using reachability_compatible by auto
  moreover from \<open>op \<prec>\<^sup>*\<^sup>* s x\<close> have "s \<prec> x \<or> s = x"
    by induction auto
  ultimately show ?thesis by auto
qed

lemma subsumption_step:
  "\<exists> a'' b'. a' \<preceq> a'' \<and> b \<preceq> b' \<and> RE a'' b' \<and> G.reachable a''" if
  "reachable a" "E a b" "G.reachable a'" "a \<preceq> a'"
proof -
  from mono[OF \<open>a \<preceq> a'\<close> \<open>E a b\<close> \<open>reachable a\<close>] \<open>G.reachable a'\<close> obtain b' where "E a' b'" "b \<preceq> b'"
    by auto
  from reachable_has_surrogate[OF \<open>G.reachable a'\<close>] obtain a''
    where "a' \<preceq> a''" "G.reachable a''" and *: "\<forall> s'. E a'' s' \<longrightarrow> RE a'' s'"
    by auto
  from mono[OF \<open>a' \<preceq> a''\<close> \<open>E a' b'\<close>] \<open>G.reachable a'\<close> \<open>G.reachable a''\<close> obtain b'' where
    "E a'' b''" "b' \<preceq> b''"
    by auto
  with * \<open>a' \<preceq> a''\<close> \<open>b \<preceq> b'\<close> \<open>G.reachable a''\<close> show ?thesis by auto
qed

lemma subsumption_step':
  "\<exists> b' xs. b \<preceq> b' \<and> G'.steps xs \<and> hd xs = a' \<and> last xs = b' \<and> length xs > 1" if
  "reachable a" "E a b" "G'.reachable a'" "a \<preceq> a'"
proof -
  from mono[OF \<open>a \<preceq> a'\<close> \<open>E a b\<close> \<open>reachable a\<close>] \<open>G'.reachable a'\<close> obtain b' where "E a' b'" "b \<preceq> b'"
    by auto
  from reachable_has_surrogate'[of a'] \<open>G'.reachable a'\<close> obtain a'' xs where *:
    "G'.steps xs" "xs \<noteq> []" "hd xs = a'" "last xs = a''" "a' \<preceq> a''" "(\<forall>s'. E a'' s' \<longrightarrow> RE a'' s')"
    by auto
  with \<open>G'.reachable a'\<close> have "G'.reachable a''"
    by (blast intro: G'.reachable_steps_append)
  with mono[OF \<open>a' \<preceq> a''\<close> \<open>E a' b'\<close>] \<open>G'.reachable a'\<close> obtain b'' where
    "E a'' b''" "b' \<preceq> b''"
    by auto
  with * \<open>a' \<preceq> a''\<close> \<open>b \<preceq> b'\<close> \<open>G'.reachable a''\<close> show ?thesis
    by (inst_existentials b'' "xs @ [b'']") (auto intro: G'.steps_append_single)
qed

theorem reachability_complete':
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "E\<^sup>*\<^sup>* a s" "G.reachable a"
  using that
proof (induction)
  case base
  then show ?case by auto
next
  case (step s t)
  then obtain s' where "s \<preceq> s'" "G.reachable s'"
    by auto
  with step(4) have "reachable a" "G.reachable s'"
    by auto
  with step(1) have "reachable s"
    by (auto simp: reachable_def)
  from subsumption_step[OF \<open>reachable s\<close> \<open>E s t\<close> \<open>G.reachable s'\<close> \<open>s \<preceq> s'\<close>] guess s'' t' by clarify
  with \<open>G.reachable s'\<close> show ?case
    by (auto simp: reachable_def)
qed

theorem steps_complete':
  "\<exists> ys. list_all2 (op \<preceq>) xs ys \<and> G.steps (a # ys)" if
  "steps (a # xs)" "G.reachable a"
  using that
proof (induction "a # xs" arbitrary: a xs rule: steps_alt_induct)
  case (Single x)
  then show ?case by auto
oops

theorem steps_complete':
  "\<exists> c ys. list_all2 (op \<preceq>) xs ys \<and> G.steps (c # ys) \<and> b \<preceq> c" if
  "steps (a # xs)" "reachable a" "a \<preceq> b" "G.reachable b"
oops

(* XXX Does this hold? *)
theorem run_complete':
  "\<exists> ys. stream_all2 (op \<preceq>) xs ys \<and> G.run (a ## ys)" if "run (a ## xs)" "G.reachable a"
proof -
  define f where "f = (\<lambda> x b. SOME y. x \<preceq> y \<and> RE b y)"
  define gen where "gen a xs = sscan f xs a" for a xs
  have gen_ctr: "gen x xs = f (shd xs) x ## gen (f (shd xs) x) (stl xs)" for x xs
    unfolding gen_def by (subst sscan.ctr) (rule HOL.refl)
  from that have "G.run (gen a xs)"
  proof (coinduction arbitrary: a xs)
    case run
    then show ?case
      apply (cases xs)
      apply auto
      apply (subst gen_ctr)
      apply simp
      apply (subst gen_ctr)
      apply simp
      apply rule
oops

corollary reachability_complete:
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "reachable s"
  using reachability_complete'[of s\<^sub>0 s] that unfolding reachable_def by auto

corollary reachability_correct:
  "(\<exists> s'. s \<preceq> s' \<and> reachable s') \<longleftrightarrow> (\<exists> s'. s \<preceq> s' \<and> G.reachable s')"
  using reachability_complete by blast

lemma G_steps_G'_steps[intro]:
  "G'.steps as" if "G.steps as"
  using that
  by induction auto

lemma steps_G'_steps:
  "\<exists> ys ns. list_all2 (op \<preceq>) xs (sublist ys ns) \<and> G'.steps (b # ys)" if
  "steps (a # xs)" "reachable a" "a \<preceq> b" "G'.reachable b"
  using that
proof (induction "a # xs" arbitrary: a b xs)
  case (Single)
  then show ?case by force
next
  case (Cons x y xs)
  from subsumption_step'[OF \<open>reachable x\<close> \<open>E x y\<close> _ \<open>x \<preceq> b\<close>] \<open>G'.reachable b\<close> obtain b' as where
    "y \<preceq> b'" "G'.steps as" "hd as = b" "last as = b'" "length as > 1"
    by auto
  with \<open>reachable x\<close> Cons.hyps(1) Cons.prems(3) obtain ys ns where
    "list_all2 op \<preceq> xs (sublist ys ns)" "G'.steps (b' # ys)"
    by atomize_elim (rule Cons.hyps(3)[OF _ \<open>y \<preceq> b'\<close>]; auto intro: G'.reachable_steps_append)
  with \<open>G'.steps as\<close> \<open>last as = b'\<close> have "G'.steps (as @ ys)"
    using G'.steps_append by force
  with \<open>hd as = b\<close> \<open>y \<preceq> b'\<close> \<open>last as = b'\<close> \<open>length as > 1\<close> show ?case
    apply (inst_existentials "tl as @ ys" "{length as - 2} \<union> {n + length as - 1 | n. n \<in> ns}")
    subgoal
      apply (subst sublist_split)
       apply force
      apply (subst sublist_nth, (simp; fail))
      apply simp
      apply safe
      subgoal
        by (subst nth_append) (cases as; auto simp: last_conv_nth)
      apply (subst sublist_shift)
       apply force
      subgoal premises prems
      proof -
        from \<open>Suc 0 < _\<close> have
          "{x - length (tl as) |x. x \<in> {n + length as - Suc 0 |n. n \<in> ns}} = ns"
          by force
        with \<open>list_all2 _ _ _\<close> show ?thesis by auto
      qed
      done
    subgoal
      by (cases as) auto
    done
qed

lemma cycle_G'_cycle:
  assumes "steps (x # xs @ [x])" "G.reachable x"
  shows "\<exists> y ys. x \<preceq> y \<and> G'.steps (y # ys @ [y]) \<and> G'.reachable y"
proof -
  let ?n  = "card {x. G'.reachable x} + 1"
  let ?xs = "x # concat (replicate ?n (xs @ [x]))"
  from steps_replicate[of "x # xs @ [x]" ?n] assms(1) have "steps ?xs"
    by auto
  from steps_G'_steps[OF this, of x] \<open>G.reachable x\<close> obtain ys ns where ys:
    "list_all2 op \<preceq> (concat (replicate ?n (xs @ [x]))) (sublist ys ns)" "G'.steps (x # ys)"
    by auto
  let ?ys = "filter (op \<preceq> x) ys"
  have "length ?ys \<ge> ?n"
    using list_all2_replicate_elem_filter[OF ys(1), of x]
    using filter_sublist_length[of "(op \<preceq> x)" ys ns]
    by auto
  have "set ?ys \<subseteq> set ys"
    by auto
  also have "\<dots> \<subseteq> {x. G'.reachable x}"
    using \<open>G'.steps _\<close> \<open>G.reachable x\<close>
    by clarsimp (rule G'.reachable_steps_elem[rotated], assumption, auto)
  finally have "\<not> distinct ?ys"
    using distinct_card[of ?ys] \<open>_ >= ?n\<close>
    by - (rule ccontr; drule distinct_length_le[OF G'_finite_reachable]; simp)
  from not_distinct_decomp[OF this] obtain as y bs cs where "?ys = as @ [y] @ bs @ [y] @ cs"
    by auto
  then obtain as' bs' cs' where
    "ys = as' @ [y] @ bs' @ [y] @ cs'"
    apply atomize_elim
    apply simp
    apply (drule filter_eq_appendD filter_eq_ConsD filter_eq_appendD[OF sym], clarify)+
    apply clarsimp
    subgoal for as1 as2 bs1 bs2 cs'
      by (inst_existentials "as1 @ as2" "bs1 @ bs2") simp
    done
  with \<open>G'.steps _\<close> have "G'.steps (y # bs' @ [y])"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x # ys)\<close> \<open>ys = _\<close> have "G'.steps (x # as' @ (y # bs' @ [y]) @ cs')"
      by auto
    then show ?thesis
      by - ((simp; fail) | drule G'.steps_ConsD G'.steps_appendD1 G'.steps_appendD2)+
  qed
  moreover have "G'.reachable y"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x # ys)\<close> \<open>ys = _\<close> have "G'.steps ((x # as' @ [y]) @ bs' @ y # cs')"
      by auto
    from G'.steps_appendD1[OF this] have "G'.steps (x # as' @ [y])"
      by simp
    with \<open>G.reachable x\<close> show ?thesis
      by - (rule G'.reachable_steps_append, auto)
  qed
  moreover from \<open>?ys = _\<close> have "x \<preceq> y"
  proof -
    from \<open>?ys = _\<close> have "y \<in> set ?ys" by auto
    then show ?thesis by auto
  qed
  ultimately show ?thesis by auto
qed

lemma cycle_G'_cycle':
  assumes "steps (s\<^sub>0 # ws @ x # xs @ [x])"
  shows "\<exists> y ys. x \<preceq> y \<and> G'.steps (y # ys @ [y]) \<and> G'.reachable y"
proof -
  let ?n  = "card {x. G'.reachable x} + 1"
  let ?xs = "x # concat (replicate ?n (xs @ [x]))"
  from assms(1) have "steps (x # xs @ [x])"
    by (auto dest: stepsD)
  with steps_replicate[of "x # xs @ [x]" ?n] have "steps ?xs"
    by auto
  then have "steps (s\<^sub>0 # ws @ ?xs)"
  proof -
    from assms have "steps ((s\<^sub>0 # ws @ [x]) @ xs @ [x])"
      by auto
    then have "steps (s\<^sub>0 # ws @ [x])"
      by (fastforce dest: stepsD)
    from steps_append[OF this \<open>steps ?xs\<close>] show ?thesis
      by auto
  qed
  from steps_G'_steps[OF this, of s\<^sub>0] obtain ys ns where ys:
    "list_all2 op \<preceq> (ws @ x # concat (replicate ?n (xs @ [x]))) (sublist ys ns)"
    "G'.steps (s\<^sub>0 # ys)"
    by auto
  then obtain x' ys' ns' where ys':
    "G'.steps (x' # ys')" "G'.reachable x'"
    "list_all2 op \<preceq> (concat (replicate ?n (xs @ [x]))) (sublist ys' ns')"
    apply atomize_elim
    apply auto
    apply (subst (asm) list_all2_append1)
    apply safe
    apply (subst (asm) list_all2_Cons1)
    apply safe
    apply (drule sublist_eq_appendD)
    apply safe
    apply (drule sublist_eq_ConsD)
    apply safe
    subgoal for ys1 ys2 z ys3 ys4 ys5 ys6 ys7 i
      apply (inst_existentials z ys7)
      subgoal
        by (auto dest: G'.stepsD)
      subgoal premises prems
      proof -
        from prems have "G'.steps ((s\<^sub>0 # ys4 @ ys6 @ [z]) @ ys7)"
          by auto
        then have "G'.steps (s\<^sub>0 # ys4 @ ys6 @ [z])"
          by (fastforce dest: G'.stepsD)
        then show ?thesis
          by - (rule G'.reachable_steps_elem, auto)
      qed
      by force
    done
  let ?ys = "filter (op \<preceq> x) ys'"
  have "length ?ys \<ge> ?n"
    using list_all2_replicate_elem_filter[OF ys'(3), of x]
    using filter_sublist_length[of "(op \<preceq> x)" ys' ns']
    by auto
  have "set ?ys \<subseteq> set ys'"
    by auto
  also have "\<dots> \<subseteq> {x. G'.reachable x}"
    using \<open>G'.steps (x' # _)\<close> \<open>G'.reachable x'\<close>
    by clarsimp (rule G'.reachable_steps_elem[rotated], assumption, auto)
  finally have "\<not> distinct ?ys"
    using distinct_card[of ?ys] \<open>_ >= ?n\<close>
    by - (rule ccontr; drule distinct_length_le[OF G'_finite_reachable]; simp)
  from not_distinct_decomp[OF this] obtain as y bs cs where "?ys = as @ [y] @ bs @ [y] @ cs"
    by auto
  then obtain as' bs' cs' where
    "ys' = as' @ [y] @ bs' @ [y] @ cs'"
    apply atomize_elim
    apply simp
    apply (drule filter_eq_appendD filter_eq_ConsD filter_eq_appendD[OF sym], clarify)+
    apply clarsimp
    subgoal for as1 as2 bs1 bs2 cs'
      by (inst_existentials "as1 @ as2" "bs1 @ bs2") simp
    done
  have "G'.steps (y # bs' @ [y])"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x' # _)\<close> \<open>ys' = _\<close> have "G'.steps (x' # as' @ (y # bs' @ [y]) @ cs')"
      by auto
    then show ?thesis
      by - ((simp; fail) | drule G'.stepsD)+
  qed
  moreover have "G'.reachable y"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x' # ys')\<close> \<open>ys' = _\<close> have "G'.steps ((x' # as' @ [y]) @ bs' @ y # cs')"
      by auto
    from G'.steps_appendD1[OF this] have "G'.steps (x' # as' @ [y])"
      by simp
    with \<open>G'.reachable x'\<close> show ?thesis
      by - (rule G'.reachable_steps_append, auto)
  qed
  moreover from \<open>?ys = _\<close> have "x \<preceq> y"
  proof -
    from \<open>?ys = _\<close> have "y \<in> set ?ys" by auto
    then show ?thesis by auto
  qed
  ultimately show ?thesis by auto
qed

lemma cycle_G'_cycle'':
  assumes "steps (s\<^sub>0 # ws @ x # xs @ [x])"
  shows "\<exists> x' xs' ys'. x \<preceq> x' \<and> G'.steps (s\<^sub>0 # xs' @ x' # ys' @ [x'])"
proof -
  let ?n  = "card {x. G'.reachable x} + 1"
  let ?xs = "x # concat (replicate ?n (xs @ [x]))"
  from assms(1) have "steps (x # xs @ [x])"
    by (auto dest: stepsD)
  with steps_replicate[of "x # xs @ [x]" ?n] have "steps ?xs"
    by auto
  then have "steps (s\<^sub>0 # ws @ ?xs)"
  proof -
    from assms have "steps ((s\<^sub>0 # ws @ [x]) @ xs @ [x])"
      by auto
    then have "steps (s\<^sub>0 # ws @ [x])"
      by (fastforce dest: stepsD)
    from steps_append[OF this \<open>steps ?xs\<close>] show ?thesis
      by auto
  qed
  from steps_G'_steps[OF this, of s\<^sub>0] obtain ys ns where ys:
    "list_all2 op \<preceq> (ws @ x # concat (replicate ?n (xs @ [x]))) (sublist ys ns)"
    "G'.steps (s\<^sub>0 # ys)"
    by auto
  then obtain x' ys' ns' ws' where ys':
    "G'.steps (x' # ys')" "G'.steps (s\<^sub>0 # ws' @ [x'])"
    "list_all2 op \<preceq> (concat (replicate ?n (xs @ [x]))) (sublist ys' ns')"
    apply atomize_elim
    apply auto
    apply (subst (asm) list_all2_append1)
    apply safe
    apply (subst (asm) list_all2_Cons1)
    apply safe
    apply (drule sublist_eq_appendD)
    apply safe
    apply (drule sublist_eq_ConsD)
    apply safe
    subgoal for ys1 ys2 z ys3 ys4 ys5 ys6 ys7 i
      apply (inst_existentials z ys7)
      subgoal
        by (auto dest: G'.stepsD)
      subgoal premises prems
      proof -
        from prems have "G'.steps ((s\<^sub>0 # ys4 @ ys6 @ [z]) @ ys7)"
          by auto
        moreover then have "G'.steps (s\<^sub>0 # ys4 @ ys6 @ [z])"
          by (fastforce dest: G'.stepsD)
        ultimately show ?thesis
          by (inst_existentials "ys4 @ ys6") auto
      qed
      by force
    done
  let ?ys = "filter (op \<preceq> x) ys'"
  have "length ?ys \<ge> ?n"
    using list_all2_replicate_elem_filter[OF ys'(3), of x]
    using filter_sublist_length[of "(op \<preceq> x)" ys' ns']
    by auto
  from \<open>G'.steps (s\<^sub>0 # ws' @ [x'])\<close> have "G'.reachable x'"
    by (auto intro: G'.steps_reachable)
  have "set ?ys \<subseteq> set ys'"
    by auto
  also have "\<dots> \<subseteq> {x. G'.reachable x}"
    using \<open>G'.steps (x' # _)\<close> \<open>G'.reachable x'\<close>
    by clarsimp (rule G'.reachable_steps_elem[rotated], assumption, auto)
  finally have "\<not> distinct ?ys"
    using distinct_card[of ?ys] \<open>_ >= ?n\<close>
    by - (rule ccontr; drule distinct_length_le[OF G'_finite_reachable]; simp)
  from not_distinct_decomp[OF this] obtain as y bs cs where "?ys = as @ [y] @ bs @ [y] @ cs"
    by auto
  then obtain as' bs' cs' where
    "ys' = as' @ [y] @ bs' @ [y] @ cs'"
    apply atomize_elim
    apply simp
    apply (drule filter_eq_appendD filter_eq_ConsD filter_eq_appendD[OF sym], clarify)+
    apply clarsimp
    subgoal for as1 as2 bs1 bs2 cs'
      by (inst_existentials "as1 @ as2" "bs1 @ bs2") simp
    done
  have "G'.steps (y # bs' @ [y])"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x' # _)\<close> \<open>ys' = _\<close> have "G'.steps (x' # as' @ (y # bs' @ [y]) @ cs')"
      by auto
    then show ?thesis
      by - ((simp; fail) | drule G'.stepsD)+
  qed
  moreover have "G'.steps (s\<^sub>0 # ws' @ x' # as' @ [y])"
  proof -
    (* XXX Decision procedure? *)
    from \<open>G'.steps (x' # ys')\<close> \<open>ys' = _\<close> have "G'.steps ((x' # as' @ [y]) @ bs' @ y # cs')"
      by auto
    from G'.steps_appendD1[OF this] have "G'.steps (x' # as' @ [y])"
      by simp
    with \<open>G'.steps (s\<^sub>0 # ws' @ [x'])\<close> show ?thesis
      by (auto dest: G'.steps_append)
  qed
  moreover from \<open>?ys = _\<close> have "x \<preceq> y"
  proof -
    from \<open>?ys = _\<close> have "y \<in> set ?ys" by auto
    then show ?thesis by auto
  qed
  ultimately show ?thesis
    by (inst_existentials y "ws' @ x' # as'" bs') (auto dest: G'.steps_append)
qed

corollary G'_reachability_complete:
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "G'.reachable s"
  using reachability_complete that by auto

end (* Reachability Compatible Subsumption Graph *)

corollary (in Reachability_Compatible_Subsumption_Graph_Final) reachability_correct:
  "(\<exists> s'. reachable s' \<and> F s') \<longleftrightarrow> (\<exists> s'. G.reachable s' \<and> F s')"
  using reachability_complete by blast

context Subsumption_Graph_Pre
begin

lemma steps_append_subsumption:
  assumes "steps (x # xs)" "steps (y # ys)" "y \<preceq> last (x # xs)" "reachable x" "reachable y"
  shows "\<exists> ys'. steps (x # xs @ ys') \<and> list_all2 op \<preceq> ys ys'"
proof -
  from assms have "reachable (last (x # xs))"
    by - (rule reachable_steps_elem, auto)
  from steps_mono[OF \<open>steps (y # ys)\<close> \<open>y \<preceq> _\<close> \<open>reachable y\<close> this] obtain ys' where
    "steps (last (x # xs) # ys')" "list_all2 op \<preceq> ys ys'"
    by auto
  with steps_append[OF \<open>steps (x # xs)\<close> this(1)] show ?thesis
    by auto
qed

lemma steps_replicate_subsumption:
  assumes "x \<preceq> last (x # xs)" "steps (x # xs)" "n > 0" "reachable x"
  shows "\<exists> ys. steps (x # ys) \<and> list_all2 (op \<preceq>) (concat (replicate n xs)) ys"
  using assms
proof (induction n)
  case 0
  then show ?case by simp
next
  case (Suc n)
  show ?case
  proof (cases n)
    case 0
    with Suc.prems show ?thesis
      by (inst_existentials xs) (auto intro: list_all2_refl)
  next
    case prems: (Suc n')
    with Suc \<open>n = _\<close> obtain ys where ys:
      "list_all2 op \<preceq> (concat (replicate n xs)) ys" "steps (x # ys)"
      by auto
    with \<open>n = _\<close> have "list_all2 op \<preceq> (concat (replicate n' xs) @ xs) ys"
      by (metis append_Nil2 concat.simps(1,2) concat_append replicate_Suc replicate_append_same)
    with \<open>x \<preceq> _\<close> have "x \<preceq> last (x # ys)"
      by (cases xs; auto dest: list_all2_last split: if_split_asm simp: list_all2_Cons1)
    from steps_append_subsumption[OF \<open>steps (x # ys)\<close> \<open>steps (x # xs)\<close> this] \<open>reachable x\<close> obtain
      ys' where "steps (x # ys @ ys')" "list_all2 op \<preceq> xs ys'"
      by auto
    with ys(1) \<open>n = _\<close> show ?thesis
      apply (inst_existentials "ys @ ys'")
      by auto
        (metis
          append_Nil2 concat.simps(1,2) concat_append list_all2_appendI replicate_Suc
          replicate_append_same
        )
  qed
qed

context
  assumes finite_reachable: "finite {x. reachable x}"
begin

(* XXX Unused *)
lemma wf_less_on_reachable_set:
  "wf {(x, y). y \<prec> x \<and> reachable x \<and> reachable y}" (is "wf ?S")
proof (rule finite_acyclic_wf)
  have "?S \<subseteq> {(x, y). reachable x \<and> reachable y}"
    by auto
  also have "finite \<dots>"
    using finite_reachable by auto
  finally show "finite ?S" .
next
  show "acyclicP (\<lambda>x y. y \<prec> x \<and> reachable x \<and> reachable y)"
    by (rule acyclicI_order[where f = id]) auto
qed

text \<open>
  This shows that looking for cycles and pre-cycles is equivalent in monotone subsumption graphs.
\<close>
(* XXX Duplication -- cycle_G'_cycle'' *)
lemma pre_cycle_cycle:
  (* XXX Move to different locale *)
  assumes A: "x \<preceq> x'" "steps (x # xs @ [x'])" "reachable x"
  shows "\<exists> x'' ys. x' \<preceq> x'' \<and> steps (x'' # ys @ [x'']) \<and> reachable x''"
proof -
  let ?n  = "card {x. reachable x} + 1"
  let ?xs = "concat (replicate ?n (xs @ [x']))"
  from steps_replicate_subsumption[OF _ \<open>steps _\<close>, of ?n] \<open>reachable x\<close> \<open>x \<preceq> x'\<close> obtain ys where
    "steps (x # ys)" "list_all2 (op \<preceq>) ?xs ys"
    by auto
  let ?ys = "filter (op \<preceq> x') ys"
  have "length ?ys \<ge> ?n"
    using list_all2_replicate_elem_filter[OF \<open>list_all2 (op \<preceq>) ?xs ys\<close>, of x']
    by auto
  have "set ?ys \<subseteq> set ys"
    by auto
  also have "\<dots> \<subseteq> {x. reachable x}"
    using \<open>steps (x # ys)\<close> \<open>reachable x\<close>
    by clarsimp (rule reachable_steps_elem[rotated], assumption, auto)
  finally have "\<not> distinct ?ys"
    using distinct_card[of ?ys] \<open>_ >= ?n\<close>
    by - (rule ccontr; drule distinct_length_le[OF finite_reachable]; simp)
  from not_distinct_decomp[OF this] obtain as y bs cs where "?ys = as @ [y] @ bs @ [y] @ cs"
    by auto
  then obtain as' bs' cs' where
    "ys = as' @ [y] @ bs' @ [y] @ cs'"
    apply atomize_elim
    apply simp
    apply (drule filter_eq_appendD filter_eq_ConsD filter_eq_appendD[OF sym], clarify)+
    apply clarsimp
    subgoal for as1 as2 bs1 bs2 cs'
      by (inst_existentials "as1 @ as2" "bs1 @ bs2") simp
    done
  have "steps (y # bs' @ [y])"
  proof -
    (* XXX Decision procedure? *)
    from \<open>steps (x # ys)\<close> \<open>ys = _\<close> have "steps (x # as' @ (y # bs' @ [y]) @ cs')"
      by auto
    then show ?thesis
      by - ((simp; fail) | drule stepsD)+
  qed
  moreover have "reachable y"
  proof -
    from \<open>steps (x # ys)\<close> \<open>ys = _\<close> have "steps ((x # as' @ [y]) @ (bs' @ y # cs'))"
      by simp
    then have "steps (x # as' @ [y])"
      by (blast dest: stepsD)
    with \<open>reachable x\<close> show ?thesis
      by (auto intro: reachable_steps_append)
  qed
  moreover from \<open>?ys = _\<close> have "x' \<preceq> y"
  proof -
    from \<open>?ys = _\<close> have "y \<in> set ?ys" by auto
    then show ?thesis by auto
  qed
  ultimately show ?thesis
    by auto
qed

end (* Finite Reachable Subgraph *)

end (* Subsumption Graph Pre *)


section \<open>Liveness\<close>

theorem (in Liveness_Compatible_Subsumption_Graph) cycle_iff:
  "(\<exists> x xs. steps   (x # xs @ [x]) \<and> reachable x   \<and> F x) \<longleftrightarrow>
   (\<exists> x xs. G.steps (x # xs @ [x]) \<and> G.reachable x \<and> F x)"
proof (safe, goal_cases)
  -- \<open>steps \<open>\<rightarrow>\<close> G.steps\<close>
  case prems: (1 x xs)
  with reachable_cycle_iff[of x xs] obtain ws where
    "steps (s\<^sub>0 # ws @ x # xs @ [x])"
    by auto
  from cycle_G'_cycle'[OF this] obtain y ys where
    "x \<preceq> y" "G'.steps (y # ys @ [y])" "G'.reachable y"
    by auto
  with \<open>F x\<close> show ?case
    by (auto intro: no_subsumption_cycle)
qed auto


section \<open>Old Material\<close>

locale Reachability_Compatible_Subsumption_Graph' = Subsumption_Graph_Defs + Partial_Order +
  assumes reachability_compatible:
    "\<forall> s. G.reachable s \<longrightarrow> (\<forall> s'. E s s' \<longrightarrow> RE s s') \<or> (\<exists> t. s \<prec> t \<and> G.reachable t)"
  assumes subgraph: "\<forall> s s'. RE s s' \<longrightarrow> E s s'"
  assumes finite_reachable: "finite {a. G.reachable a}"
  assumes mono:
    "a \<preceq> b \<Longrightarrow> E a a' \<Longrightarrow> reachable a \<Longrightarrow> G.reachable b \<Longrightarrow> \<exists> b'. E b b' \<and> a' \<preceq> b'"
begin

lemma subgraph'[intro]:
  "E s s'" if "RE s s'"
  using that subgraph by blast

lemma G_reachability_sound[intro]:
  "reachable a" if "G.reachable a"
  using that unfolding reachable_def G.reachable_def by (induction; blast intro: rtranclp.intros(2))

lemma G_steps_sound[intro]:
  "steps xs" if "G.steps xs"
  using that by induction auto

lemma G_run_sound[intro]:
  "run xs" if "G.run xs"
  using that by (coinduction arbitrary: xs) (auto 4 3 elim: G.run.cases)

lemma reachable_has_surrogate:
  "\<exists> t. G.reachable t \<and> s \<preceq> t \<and> (\<forall> s'. E t s' \<longrightarrow> RE t s')" if "G.reachable s"
  using that
proof -
  from finite_reachable \<open>G.reachable s\<close> obtain x where
    "\<forall>s'. E x s' \<longrightarrow> RE x s'" "G.reachable x" "op \<prec>\<^sup>*\<^sup>* s x"
    apply atomize_elim
    apply (induction rule: rtranclp_ev_induct2)
    using reachability_compatible by auto
  moreover from \<open>op \<prec>\<^sup>*\<^sup>* s x\<close> have "s \<prec> x \<or> s = x"
    by induction auto
  ultimately show ?thesis by auto
qed

lemma subsumption_step:
  "\<exists> a'' b'. a' \<preceq> a'' \<and> b \<preceq> b' \<and> RE a'' b' \<and> G.reachable a''" if
  "reachable a" "E a b" "G.reachable a'" "a \<preceq> a'"
proof -
  from mono[OF \<open>a \<preceq> a'\<close> \<open>E a b\<close> \<open>reachable a\<close> \<open>G.reachable a'\<close>] obtain b' where "E a' b'" "b \<preceq> b'"
    by auto
  from reachable_has_surrogate[OF \<open>G.reachable a'\<close>] obtain a''
    where "a' \<preceq> a''" "G.reachable a''" and *: "\<forall> s'. E a'' s' \<longrightarrow> RE a'' s'"
    by auto
  from mono[OF \<open>a' \<preceq> a''\<close> \<open>E a' b'\<close>] \<open>G.reachable a'\<close> \<open>G.reachable a''\<close> obtain b'' where
    "E a'' b''" "b' \<preceq> b''"
    by auto
  with * \<open>a' \<preceq> a''\<close> \<open>b \<preceq> b'\<close> \<open>G.reachable a''\<close> show ?thesis by auto
qed

theorem reachability_complete':
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "E\<^sup>*\<^sup>* a s" "G.reachable a"
  using that
proof (induction)
  case base
  then show ?case by auto
next
  case (step s t)
  then obtain s' where "s \<preceq> s'" "G.reachable s'"
    by auto
  with step(4) have "reachable a" "G.reachable s'"
    by auto
  with step(1) have "reachable s"
    by (auto simp: reachable_def)
  from subsumption_step[OF \<open>reachable s\<close> \<open>E s t\<close> \<open>G.reachable s'\<close> \<open>s \<preceq> s'\<close>] guess s'' t' by clarify
  with \<open>G.reachable s'\<close> show ?case
    by (auto simp: reachable_def)
qed

theorem steps_complete':
  "\<exists> ys. list_all2 (op \<preceq>) xs ys \<and> G.steps (a # ys)" if
  "steps (a # xs)" "G.reachable a"
  using that
proof (induction "a # xs" arbitrary: a xs rule: steps_alt_induct)
  case (Single x)
  then show ?case by auto
oops

theorem steps_complete':
  "\<exists> c ys. list_all2 (op \<preceq>) xs ys \<and> G.steps (c # ys) \<and> b \<preceq> c" if
  "steps (a # xs)" "reachable a" "a \<preceq> b" "G.reachable b"
  using that
proof (induction "a # xs" arbitrary: a b xs)
  case (Single x)
  then show ?case by auto
next
  case (Cons x y xs)
  from subsumption_step[OF \<open>reachable x\<close> \<open>E _ _\<close> \<open>G.reachable b\<close> \<open>x \<preceq> b\<close>] guess b' y' by clarify
  with Cons obtain y'' ys where "list_all2 op \<preceq> xs ys" "G.steps (y'' # ys)" "y' \<preceq> y''"
    by fastforce
  with \<open>RE _ _\<close> \<open>y \<preceq> y'\<close> show ?case
    apply (inst_existentials b' "y'' # ys")
     apply auto
      apply rule
oops


(* XXX Does this hold? *)
theorem run_complete':
  "\<exists> ys. stream_all2 (op \<preceq>) xs ys \<and> G.run (a ## ys)" if "run (a ## xs)" "G.reachable a"
proof -
  define f where "f = (\<lambda> x b. SOME y. x \<preceq> y \<and> RE b y)"
  define gen where "gen a xs = sscan f xs a" for a xs
  have gen_ctr: "gen x xs = f (shd xs) x ## gen (f (shd xs) x) (stl xs)" for x xs
    unfolding gen_def by (subst sscan.ctr) (rule HOL.refl)
  from that have "G.run (gen a xs)"
  proof (coinduction arbitrary: a xs)
    case run
    then show ?case
      apply (cases xs)
      apply auto
      apply (subst gen_ctr)
      apply simp
      apply (subst gen_ctr)
      apply simp
      apply rule
oops

corollary reachability_complete:
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "reachable s"
  using reachability_complete'[of s\<^sub>0 s] that unfolding reachable_def by auto

corollary reachability_correct:
  "(\<exists> s'. s \<preceq> s' \<and> reachable s') \<longleftrightarrow> (\<exists> s'. s \<preceq> s' \<and> G.reachable s')"
  using reachability_complete by blast

lemma G'_reachability_sound[intro]:
  "reachable a" if "G'.reachable a"
  using that unfolding G'.reachable_def reachable_def
  by (induction;
      blast intro: rtranclp.intros(2) G_reachability_sound[unfolded reachable_def G.reachable_def])

corollary G'_reachability_complete:
  "\<exists> s'. s \<preceq> s' \<and> G.reachable s'" if "G'.reachable s"
  using reachability_complete that by auto

end (* Reachability Compatible Subsumption Graph' *)