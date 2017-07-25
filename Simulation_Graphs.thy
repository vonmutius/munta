theory Simulation_Graphs
  imports
    "library/CTL"
    "library/More_List"
    Normalized_Zone_Semantics
    "~/Isabelle/Util/Explorer"
begin

chapter \<open>Simulation Graphs\<close>

paragraph \<open>Misc\<close>

text \<open>
  A directed graph where every node has at least one ingoing edge, contains a directed cycle.
\<close>
lemma directed_graph_indegree_ge_1_cycle:
  assumes "finite S" "S \<noteq> {}" "\<forall> y \<in> S. \<exists> x \<in> S. E x y"
  shows "\<exists> x \<in> S. \<exists> y. E x y \<and> E\<^sup>*\<^sup>* y x"
  using assms
proof (induction arbitrary: E rule: finite_ne_induct)
  case (singleton x)
  then show ?case by auto
next
  case (insert x S E)
  from insert.prems obtain y where "y \<in> insert x S" "E y x"
    by auto
  show ?case
  proof (cases "y = x")
    case True
    with \<open>E y x\<close> show ?thesis by auto
  next
    case False
    with \<open>y \<in> _\<close> have "y \<in> S" by auto
    define E' where "E' a b \<equiv> E a b \<or> (a = y \<and> E x b)" for a b
    have E'_E: "\<exists> c. E a c \<and> E\<^sup>*\<^sup>* c b" if "E' a b" for a b
      using that \<open>E y x\<close> unfolding E'_def by auto
    have [intro]: "E\<^sup>*\<^sup>* a b" if "E' a b" for a b
      using that \<open>E y x\<close> unfolding E'_def by auto
    have [intro]: "E\<^sup>*\<^sup>* a b" if "E'\<^sup>*\<^sup>* a b" for a b
      using that by (induction; blast intro: rtranclp_trans)
    have "\<forall>y\<in>S. \<exists>x\<in>S. E' x y"
    proof (rule ballI)
      fix b assume "b \<in> S"
      with insert.prems obtain a where "a \<in> insert x S" "E a b"
        by auto
      show "\<exists>a\<in>S. E' a b"
      proof (cases "a = x")
        case True
        with \<open>E a b\<close> have "E' y b" unfolding E'_def by simp
        with \<open>y \<in> S\<close> show ?thesis ..
      next
        case False
        with \<open>a \<in> _\<close> \<open>E a b\<close> show ?thesis unfolding E'_def by auto
      qed
    qed
    from insert.IH[OF this] guess x y by safe
    then show ?thesis by (blast intro: rtranclp_trans dest: E'_E)
    qed
  qed

(* XXX Move? *)
lemma prod_set_fst_id:
  "x = y" if "\<forall> a \<in> x. fst a = b" "\<forall> a \<in> y. fst a = b" "snd ` x = snd ` y"
  using that by (auto 4 6 simp: fst_def snd_def image_def split: prod.splits)


section \<open>Simulation Graphs\<close>

locale Simulation_Graph_Defs = Graph_Defs C for C :: "'a \<Rightarrow> 'a \<Rightarrow> bool" +
  fixes A :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool"
begin

sublocale Steps: Graph_Defs A .

abbreviation "Steps \<equiv> Steps.steps"
abbreviation "Run \<equiv> Steps.run"

lemmas Steps_appendD1 = Steps.steps_appendD1

lemmas Steps_appendD2 = Steps.steps_appendD2

lemmas steps_alt_induct = Steps.steps_alt_induct

lemmas Steps_appendI = Steps.steps_appendI

lemmas Steps_cases = Steps.steps.cases

end (* Simulation Graph *)

locale Simulation_Graph_Poststable = Simulation_Graph_Defs +
  assumes poststable: "A S T \<Longrightarrow> \<forall> s' \<in> T. \<exists> s \<in> S. C s s'"

locale Simulation_Graph_Prestable = Simulation_Graph_Defs +
  assumes prestable: "A S T \<Longrightarrow> \<forall> s \<in> S. \<exists> s' \<in> T. C s s'"

locale Double_Simulation_Defs =
  fixes C :: "'a \<Rightarrow> 'a \<Rightarrow> bool" -- "Concrete step relation"
    and A1 :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool" -- "Step relation for the first abstraction layer"
    and P1 :: "'a set \<Rightarrow> bool" -- "Valid states of the first abstraction layer"
    and A2 :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool" -- "Step relation for the second abstraction layer"
    and P2 :: "'a set \<Rightarrow> bool" -- "Valid states of the second abstraction layer"
begin

sublocale Simulation_Graph_Defs C A2 .

sublocale pre_defs: Simulation_Graph_Defs C A1 .

definition "closure a = {x. P1 x \<and> a \<inter> x \<noteq> {}}"

definition "A2' a b \<equiv> \<exists> x y. a = closure x \<and> b = closure y \<and> A2 x y"

sublocale post_defs: Simulation_Graph_Defs A1 A2' .

lemma closure_mono:
  "closure a \<subseteq> closure b" if "a \<subseteq> b"
  using that unfolding closure_def by auto

lemma closure_intD:
  "x \<in> closure a \<and> x \<in> closure b" if "x \<in> closure (a \<inter> b)"
  using that closure_mono by blast

end (* Double Simulation Graph Defs *)

locale Double_Simulation = Double_Simulation_Defs +
  assumes prestable: "A1 S T \<Longrightarrow> \<forall> s \<in> S. \<exists> s' \<in> T. C s s'"
      and closure_poststable: "s' \<in> closure y \<Longrightarrow> A2 x y \<Longrightarrow> \<exists>s\<in>closure x. A1 s s'"
      and P1_distinct: "P1 x \<Longrightarrow> P1 y \<Longrightarrow> x \<noteq> y \<Longrightarrow> x \<inter> y = {}"
      and P1_finite: "finite {x. P1 x}"
      and P2_cover: "P2 a \<Longrightarrow> \<exists> x. P1 x \<and> x \<inter> a \<noteq> {}"
begin

sublocale post: Simulation_Graph_Poststable A1 A2'
  unfolding A2'_def by standard (auto dest: closure_poststable)

sublocale pre: Simulation_Graph_Prestable C A1 by standard (rule prestable)

end (* Double Simulation *)

locale Finite_Graph = Graph_Defs +
  fixes x\<^sub>0
  assumes finite_reachable: "finite {x. E\<^sup>*\<^sup>* x\<^sub>0 x}"

locale Simulation_Graph_Complete_Defs =
  Simulation_Graph_Defs C A for C :: "'a \<Rightarrow> 'a \<Rightarrow> bool" and A :: "'a set \<Rightarrow> 'a set \<Rightarrow> bool" +
  fixes P :: "'a set \<Rightarrow> bool" -- "well-formed abstractions"

locale Simulation_Graph_Complete = Simulation_Graph_Complete_Defs +
  assumes complete: "C x y \<Longrightarrow> P S \<Longrightarrow> x \<in> S \<Longrightarrow> \<exists> T. A S T \<and> y \<in> T"
      and P_invariant: "P S \<Longrightarrow> A S T \<Longrightarrow> P T"

locale Simulation_Graph_Finite_Complete = Simulation_Graph_Complete +
  fixes a\<^sub>0
  assumes finite_abstract_reachable: "finite {a. A\<^sup>*\<^sup>* a\<^sub>0 a}"
begin

sublocale Steps_finite: Finite_Graph A a\<^sub>0
  by standard (rule finite_abstract_reachable)

end (* Simulation Graph Finite Complete *)

locale Double_Simulation_Finite_Complete = Double_Simulation +
  fixes a\<^sub>0
  assumes complete: "C x y \<Longrightarrow> x \<in> S \<Longrightarrow> P2 S \<Longrightarrow> \<exists> T. A2 S T \<and> y \<in> T"
  assumes finite_abstract_reachable: "finite {a. A2\<^sup>*\<^sup>* a\<^sub>0 a}"
  assumes P2_invariant: "P2 a \<Longrightarrow> A2 a a' \<Longrightarrow> P2 a'"
      and P2_a\<^sub>0: "P2 a\<^sub>0"
begin

sublocale Simulation_Graph_Finite_Complete C A2 P2 a\<^sub>0
  by standard (blast intro: complete finite_abstract_reachable P2_invariant)+

sublocale P2_invariant: Graph_Invariant_Start A2 a\<^sub>0 P2
  by (standard; blast intro: P2_invariant P2_a\<^sub>0)

end (* Double Simulation Finite Complete *)

locale Simulation_Graph_Complete_Prestable = Simulation_Graph_Complete + Simulation_Graph_Prestable
begin

sublocale Graph_Invariant A P by standard (rule P_invariant)

end (* Simulation Graph Complete Prestable *)

locale Double_Simulation_Finite_Complete_Bisim = Double_Simulation_Finite_Complete +
  assumes A1_complete: "C x y \<Longrightarrow> P1 S \<Longrightarrow> x \<in> S \<Longrightarrow> \<exists> T. A1 S T \<and> y \<in> T"
      and P1_invariant: "P1 S \<Longrightarrow> A1 S T \<Longrightarrow> P1 T"
begin

sublocale bisim: Simulation_Graph_Complete_Prestable C A1 P1
  by standard (blast intro: A1_complete P1_invariant)+

end (* Double Simulation Finite Complete Bisim *)

locale Double_Simulation_Finite_Complete_Bisim_Cover = Double_Simulation_Finite_Complete_Bisim +
  assumes P2_P1_cover: "P2 a \<Longrightarrow> x \<in> a \<Longrightarrow> \<exists> a'. a \<inter> a' \<noteq> {} \<and> P1 a' \<and> x \<in> a'"

locale Double_Simulation_Finite_Complete_Abstraction_Prop =
  Double_Simulation +
  fixes a\<^sub>0
  fixes \<phi> :: "'a \<Rightarrow> bool" -- "The property we want to check"
  assumes complete: "C x y \<Longrightarrow> x \<in> S \<Longrightarrow> P2 S \<Longrightarrow> \<exists> T. A2 S T \<and> y \<in> T"
  assumes finite_abstract_reachable: "finite {a. A2\<^sup>*\<^sup>* a\<^sub>0 a}"
  assumes P2_invariant: "P2 a \<Longrightarrow> A2 a a' \<Longrightarrow> P2 a'"
      and P2_a\<^sub>0: "P2 a\<^sub>0"
  assumes \<phi>_A1_compatible: "A1 a b \<Longrightarrow> b \<subseteq> {x. \<phi> x} \<or> b \<inter> {x. \<phi> x} = {}"
      and \<phi>_P2_compatible: "P2 a \<Longrightarrow> a \<inter> {x. \<phi> x} \<noteq> {} \<Longrightarrow> P2 (a \<inter> {x. \<phi> x})"
      and \<phi>_A2_compatible: "A2\<^sup>*\<^sup>* a\<^sub>0 a \<Longrightarrow> a \<inter> {x. \<phi> x} \<noteq> {} \<Longrightarrow> A2\<^sup>*\<^sup>* a\<^sub>0 (a \<inter> {x. \<phi> x})"
      and P2_non_empty: "P2 a \<Longrightarrow> a \<noteq> {}"

locale Double_Simulation_Finite_Complete_Abstraction_Prop_Bisim =
  Double_Simulation_Finite_Complete_Abstraction_Prop + Double_Simulation_Finite_Complete_Bisim

section \<open>Poststability\<close>

context Simulation_Graph_Poststable
begin

lemma Steps_poststable:
  "\<exists> xs. steps xs \<and> list_all2 (op \<in>) xs as \<and> last xs = x" if "Steps as" "x \<in> last as"
  using that
proof induction
  case (Single a)
  then show ?case by auto
next
  case (Cons a b as)
  then guess xs by clarsimp
  then have "hd xs \<in> b" by (cases xs) auto
  with poststable[OF \<open>A a b\<close>] obtain y where "y \<in> a" "C y (hd xs)" by auto
  with \<open>list_all2 _ _ _\<close> \<open>steps _\<close> \<open>x = _\<close> show ?case by (cases xs) auto
qed

lemma Steps_steps_cycle:
  "\<exists> x xs. steps (x # xs @ [x]) \<and> (\<forall> x \<in> set xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> x \<in> a"
  if assms: "Steps (a # as @ [a])" "finite a" "a \<noteq> {}"
proof -
  define E where
    "E x y = (\<exists> xs. steps (x # xs @ [y]) \<and> (\<forall> x \<in> set xs \<union> {x, y}. \<exists> a \<in> set as \<union> {a}. x \<in> a))"
    for x y
  from assms(2-) have "\<exists> x. E x y \<and> x \<in> a" if "y \<in> a" for y
    using that unfolding E_def
    apply simp
    apply (drule Steps_poststable[OF assms(1), simplified])
    apply clarify
    subgoal for xs
      apply (inst_existentials "hd xs" "tl (butlast xs)")
      subgoal by (cases xs) auto
      subgoal by (auto elim: steps.cases dest!: list_all2_set1)
      subgoal by (drule list_all2_set1) (cases xs, auto dest: in_set_butlastD)
      by (cases xs) auto
    done
  with \<open>finite a\<close> \<open>a \<noteq> {}\<close> obtain x y where cycle: "E x y" "E\<^sup>*\<^sup>* y x" "x \<in> a"
    by (force dest!: directed_graph_indegree_ge_1_cycle[where E = E])
  have trans[intro]: "E x z" if "E x y" "E y z" for x y z
    using that unfolding E_def
    apply safe
    subgoal for xs ys
      apply (inst_existentials "xs @ y # ys")
       apply (drule steps_append, assumption; simp; fail)
      by (cases ys, auto dest: list.set_sel(2)[rotated] elim: steps.cases)
    done
  have "E x z" if "E\<^sup>*\<^sup>* y z" "E x y" "x \<in> a" for x y z
  using that proof induction
    case base
    then show ?case unfolding E_def by force
  next
    case (step y z)
    then show ?case by auto
  qed
  with cycle have "E x x" by blast
  with \<open>x \<in> a\<close> show ?thesis unfolding E_def by auto
qed

end (* Simulation Graph Poststable *)

section \<open>Prestability\<close>

context Simulation_Graph_Prestable
begin

lemma Steps_prestable:
  "\<exists> xs. steps (x # xs) \<and> list_all2 (op \<in>) (x # xs) as" if "Steps as" "x \<in> hd as"
  using that
proof (induction arbitrary: x)
  case (Single a)
  then show ?case by auto
next
  case (Cons a b as)
  from prestable[OF \<open>A a b\<close>] \<open>x \<in> _\<close> obtain y where "y \<in> b" "C x y" by auto
  with Cons.IH[of y] guess xs by clarsimp
  with \<open>x \<in> _\<close> show ?case by auto
qed

text \<open>Abstract cycles lead to concrete infinite runs.\<close>
lemma Steps_run_cycle_buechi:
  "\<exists> xs. run (x ## xs) \<and> stream_all2 op \<in> xs (cycle (as @ [a]))"
  if assms: "Steps (a # as @ [a])" "x \<in> a"
proof -
  note C = Steps_prestable[OF assms(1), simplified]
  define P where "P \<equiv> \<lambda> x xs. steps (last x # xs) \<and> list_all2 (op \<in>) xs (as @ [a])"
  define f where "f \<equiv> \<lambda> x. SOME xs. P x xs"
  from Steps_prestable[OF assms(1)] \<open>x \<in> a\<close> obtain ys where ys:
    "steps (x # ys)" "list_all2 op \<in> (x # ys) (a # as @ [a])"
    by auto
  define xs where "xs = flat (siterate f ys)"
  from ys have "P [x] ys" unfolding P_def by auto
  from \<open>P _ _\<close> have *: "\<exists> xs. P xs ys" by blast
  have P_1[intro]:"ys \<noteq> []" if "P xs ys" for xs ys using that unfolding P_def by (cases ys) auto
  have P_2[intro]: "last ys \<in> a" if "P xs ys" for xs ys
    using that P_1[OF that] unfolding P_def by (auto dest:  list_all2_last)
  from * have "stream_all2 op \<in> xs (cycle (as @ [a]))"
    unfolding xs_def proof (coinduction arbitrary: ys rule: stream_rel_coinduct_shift)
    case prems: stream_rel
    then have "ys \<noteq> []" "last ys \<in> a" by (blast dest: P_1 P_2)+
    from \<open>ys \<noteq> []\<close> C[OF \<open>last ys \<in> a\<close>] have "\<exists> xs. P ys xs" unfolding P_def by auto
    from someI_ex[OF this] have "P ys (f ys)" unfolding f_def .
    with \<open>ys \<noteq> []\<close> prems show ?case
      apply (inst_existentials ys "flat (siterate f (f ys))" "as @ [a]" "cycle (as @ [a])")
           apply (subst siterate.ctr; simp; fail)
          apply (subst cycle_decomp; simp; fail)
       by (auto simp: P_def)
  qed
  from * have "run xs"
    unfolding xs_def proof (coinduction arbitrary: ys rule: run_flat_coinduct)
    case prems: (run_shift xs ws xss ys)
    then have "ys \<noteq> []" "last ys \<in> a" by (blast dest: P_1 P_2)+
    from \<open>ys \<noteq> []\<close> C[OF \<open>last ys \<in> a\<close>] have "\<exists> xs. P ys xs" unfolding P_def by auto
    from someI_ex[OF this] have "P ys (f ys)" unfolding f_def .
    with \<open>ys \<noteq> []\<close> prems show ?case by (auto elim: steps.cases simp: P_def)
  qed
  with P_1[OF \<open>P _ _\<close>] \<open>steps (x # ys)\<close> have "run (x ## xs)"
    unfolding xs_def
    by (subst siterate.ctr, subst (asm) siterate.ctr) (cases ys; auto elim: steps.cases)
  with \<open>stream_all2 _ _ _\<close> show ?thesis by blast
qed

lemma Steps_run_cycle_buechi'':
  "\<exists> xs. run (x ## xs) \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> infs b (x ## xs)"
  if assms: "Steps (a # as @ [a])" "x \<in> a" "b \<in> set (a # as @ [a])"
  using Steps_run_cycle_buechi[OF that(1,2)] that(2,3)
  apply safe
  apply (rule exI conjI)+
   apply assumption
  apply (subst alw_ev_stl[symmetric])
  by (force dest: alw_ev_HLD_cycle[of _ _ b] stream_all2_sset1)

lemma Steps_run_cycle_buechi':
  "\<exists> xs. run (x ## xs) \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> infs a (x ## xs)"
  if assms: "Steps (a # as @ [a])" "x \<in> a"
  using Steps_run_cycle_buechi''[OF that] \<open>x \<in> a\<close> by auto

lemma Steps_run_cycle':
  "\<exists> xs. run (x ## xs) \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a)"
  if assms: "Steps (a # as @ [a])" "x \<in> a"
  using Steps_run_cycle_buechi'[OF assms] by auto

lemma Steps_run_cycle:
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> a) \<and> shd xs \<in> a"
  if assms: "Steps (a # as @ [a])" "a \<noteq> {}"
  using Steps_run_cycle'[OF assms(1)] assms(2) by force

paragraph \<open>Unused\<close>

lemma Steps_cycle_every_prestable':
  "\<exists> b y. C x y \<and> y \<in> b \<and> b \<in> set as \<union> {a}"
  if assms: "Steps (as @ [a])" "x \<in> b" "b \<in> set as"
  using assms
proof (induction "as @ [a]" arbitrary: as)
  case Single
  then show ?case by simp
next
  case (Cons a c xs)
  show ?case
  proof (cases "a = b")
    case True
    with prestable[OF \<open>A a c\<close>] \<open>x \<in> b\<close> obtain y where "y \<in> c" "C x y"
      by auto
    with \<open>a # c # _ = _\<close> show ?thesis
      apply (inst_existentials c y)
    proof (assumption+, cases as, goal_cases)
      case (2 a list)
      then show ?case by (cases list) auto
    qed simp
  next
    case False
    with Cons.hyps(3)[of "tl as"] Cons.prems Cons.hyps(1,2,4-) show ?thesis by (cases as) auto
  qed
qed

lemma Steps_cycle_first_prestable:
  "\<exists> b y. C x y \<and> x \<in> b \<and> b \<in> set as \<union> {a}" if assms: "Steps (a # as @ [a])" "x \<in> a"
proof (cases as)
  case Nil
  with assms show ?thesis by (auto elim!: Steps_cases dest: prestable)
next
  case (Cons b as)
  with assms show ?thesis by (auto 4 4 elim: Steps_cases dest: prestable)
qed

lemma Steps_cycle_every_prestable:
  "\<exists> b y. C x y \<and> y \<in> b \<and> b \<in> set as \<union> {a}"
  if assms: "Steps (a # as @ [a])" "x \<in> b" "b \<in> set as \<union> {a}"
  using assms Steps_cycle_every_prestable'[of "a # as" a] Steps_cycle_first_prestable by auto

end (* Simulation Graph Prestable *)


section \<open>Double Simulation\<close>

context Double_Simulation
begin

lemma closure_involutive:
  "closure (\<Union> closure x) = closure x"
  unfolding closure_def by (auto dest: P1_distinct)

lemma closure_finite:
  "finite (closure x)"
  using P1_finite unfolding closure_def by auto

lemma closure_non_empty:
  "closure x \<noteq> {}" if "P2 x"
  using that unfolding closure_def by (auto dest!: P2_cover)

lemma A2'_A2_closure:
  "A2' (closure x) (closure y)" if "A2 x y"
  using that unfolding A2'_def by auto

lemma Steps_Union:
  "post_defs.Steps (map closure xs)" if "Steps xs"
using that proof (induction xs rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc y xs)
  show ?case
  proof (cases xs rule: rev_cases)
    case Nil
    then show ?thesis by auto
  next
    case (snoc ys z)
    with Steps_appendD1[OF \<open>Steps (xs @ [y])\<close>] have "Steps xs" by simp
    then have *: "post_defs.Steps (map closure xs)" by (rule snoc.IH)
    with \<open>xs = _\<close> snoc.prems have "A2 z y"
      by (metis Steps.steps_appendD3 append_Cons append_assoc append_self_conv2)
    with \<open>A2 z y\<close> have "A2' (closure z) (closure y)" by (auto dest!: A2'_A2_closure)
    with * post_defs.Steps_appendI show ?thesis
      by (simp add: \<open>xs = _\<close>)
  qed
qed

lemma post_Steps_non_empty:
  "x \<noteq> {}" if "post_defs.Steps (a # as)" "x \<in> b" "b \<in> set as"
  using that
proof (induction "a # as" arbitrary: a as)
  case Single
  then show ?case by auto
next
  case (Cons a c as)
  then show ?case by (auto simp: A2'_def closure_def)
qed

lemma Steps_run_cycle':
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> \<Union> a) \<and> shd xs \<in> \<Union> a"
  if assms: "post_defs.Steps (a # as @ [a])" "finite a" "a \<noteq> {}"
proof -
  from post.Steps_steps_cycle[OF assms] guess a1 as1 by safe
  note guessed = this
  from assms(1) \<open>a1 \<in> a\<close> have "a1 \<noteq> {}" by (auto dest!: post_Steps_non_empty)
  with guessed pre.Steps_run_cycle[of a1 as1] obtain xs where
    "run xs" "\<forall>x\<in>sset xs. \<exists>a\<in>set as1 \<union> {a1}. x \<in> a" "shd xs \<in> a1"
    by atomize_elim auto
  with guessed(2,3) show ?thesis
    by (inst_existentials xs) (metis Un_iff UnionI empty_iff insert_iff)+
qed

lemma Steps_run_cycle:
  "\<exists> xs. run xs \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a}. x \<in> \<Union> closure a) \<and> shd xs \<in> \<Union> closure a"
  if assms: "Steps (a # as @ [a])" "P2 a"
proof -
  from Steps_Union[OF assms(1)] have "post_defs.Steps (closure a # map closure as @ [closure a])"
    by simp
  from Steps_run_cycle'[OF this closure_finite closure_non_empty[OF \<open>P2 a\<close>]]
    show ?thesis by (force dest: list_all2_set2)
qed

lemma Steps_run_cycle'':
  "\<exists> x xs. run (x ## xs) \<and> x \<in> \<Union> closure a\<^sub>0
  \<and> (\<forall> x \<in> sset xs. \<exists> a \<in> set as \<union> {a} \<union> set bs. x \<in> \<Union> closure a)
  \<and> infs (\<Union> closure a) (x ## xs)"
  if assms: "Steps (a\<^sub>0 # as @ a # bs @ [a])" "P2 a"
proof -
  from Steps_Union[OF assms(1)] have "post_defs.Steps (map closure (a\<^sub>0 # as @ a # bs @ [a]))"
    by simp
  note as1 = this
  from
    post_defs.Steps.steps_decomp[of "closure a\<^sub>0 # map closure as" "map closure (a # bs @ [a])"]
    as1(1)[unfolded this]
  have *:
    "post_defs.Steps (closure a\<^sub>0 # map closure as)"
    "post_defs.Steps (closure a # map closure bs @ [closure a])"
    "A2' (closure (last (a\<^sub>0 # as))) (closure a)"
    by (simp split: if_split_asm add: last_map)+
  then obtain bs1 where bs1:
    "post_defs.Steps (closure a # bs1 @ [closure a])"
    "list_all2 (\<lambda>x a. a = closure x) (a # bs @ [a]) (closure a # bs1 @ [closure a])"
    unfolding list_all2_op_map_iff by auto
  from post.Steps_steps_cycle[OF this(1) closure_finite closure_non_empty[OF \<open>P2 a\<close>]] guess a1 as1
    by safe
  note as1 = this
  with post.poststable[OF *(3)] obtain a2 where "a2 \<in> closure (last (a\<^sub>0 # as))" "A1 a2 a1"
    by auto
  with post.Steps_poststable[OF *(1), of a2] obtain as2 where as2:
    "pre_defs.Steps as2" "list_all2 op \<in> as2 (closure a\<^sub>0 # map closure as)" "last as2 = a2"
    by (auto split: if_split_asm simp: last_map)
  from as2(2) have "hd as2 \<in> closure a\<^sub>0" by (cases as2) auto
  then have "hd as2 \<noteq> {}" unfolding closure_def by auto
  then obtain x\<^sub>0 where "x\<^sub>0 \<in> hd as2" by auto
  from pre.Steps_prestable[OF as2(1) \<open>x\<^sub>0 \<in> _\<close>] obtain xs where xs:
    "steps (x\<^sub>0 # xs)" "list_all2 op \<in> (x\<^sub>0 # xs) as2"
    by auto
  with \<open>last as2 = a2\<close> have "last (x\<^sub>0 # xs) \<in> a2"
    unfolding list_all2_Cons1 by (auto intro: list_all2_last)
  with pre.prestable[OF \<open>A1 a2 a1\<close>] obtain y where "C (last (x\<^sub>0 # xs)) y" "y \<in> a1" by auto
  from pre.Steps_run_cycle_buechi'[OF as1(1) \<open>y \<in> a1\<close>] obtain ys where ys:
    "run (y ## ys)" "\<forall>x\<in>sset ys. \<exists>a\<in>set as1 \<union> {a1}. x \<in> a" "infs a1 (y ## ys)"
    by auto
  from ys(3) \<open>a1 \<in> closure a\<close> have "infs (\<Union> closure a) (y ## ys)"
    by (auto simp: HLD_iff elim!: alw_ev_mono)
  from extend_run[OF xs(1) \<open>C _ _\<close> \<open>run (y ## ys)\<close>] have "run ((x\<^sub>0 # xs) @- y ## ys)" by simp
  then show ?thesis
    apply (inst_existentials x\<^sub>0 "xs @- y ## ys")
      apply (simp; fail)
    using \<open>x\<^sub>0 \<in> _\<close> \<open>hd as2 \<in> _\<close> apply (auto; fail)
    using xs(2) as2(2) bs1(2) \<open>y \<in> a1\<close> \<open>a1 \<in> _\<close> ys(2) as1(2)
    unfolding list_all2_op_map_iff list_all2_Cons1 list_all2_Cons2
      apply auto
       apply (fastforce dest!: list_all2_set1)
     apply blast
    using \<open>infs (\<Union> closure a) (y ## ys)\<close>
    by (simp add: sdrop_shift)
qed

paragraph \<open>Unused\<close>

lemma post_Steps_P1:
  "P1 x" if "post_defs.Steps (a # as)" "x \<in> b" "b \<in> set as"
  using that
proof (induction "a # as" arbitrary: a as)
  case Single
  then show ?case by auto
next
  case (Cons a c as)
  then show ?case by (auto simp: A2'_def closure_def)
qed

end (* Double Simulation Graph *)


section \<open>Finite Graphs\<close>

context Finite_Graph
begin

subsection \<open>Infinite Büchi Runs Correspond to Finite Cycles\<close>

lemma run_finite_state_set:
  assumes "run (x\<^sub>0 ## xs)"
  shows "finite (sset (x\<^sub>0 ## xs))"
proof -
  let ?S = "{x. E\<^sup>*\<^sup>* x\<^sub>0 x}"
  from run_reachable[OF assms] have "sset xs \<subseteq> ?S" unfolding stream.pred_set by auto
  moreover have "finite ?S" using finite_reachable by auto
  ultimately show ?thesis by (auto intro: finite_subset)
qed

lemma run_finite_state_set_cycle:
  assumes "run (x\<^sub>0 ## xs)"
  shows
    "\<exists> ys zs. run (x\<^sub>0 ## ys @- cycle zs) \<and> set ys \<union> set zs \<subseteq> {x\<^sub>0} \<union> sset xs \<and> zs \<noteq> []"
proof -
  from run_finite_state_set[OF assms] have "finite (sset (x\<^sub>0 ## xs))" .
  with sdistinct_infinite_sset[of "x\<^sub>0 ## xs"] not_sdistinct_decomp[of "x\<^sub>0 ## xs"] obtain x ws ys zs
    where "x\<^sub>0 ## xs = ws @- x ## ys @- x ## zs"
    by force
  then have decomp: "x\<^sub>0 ## xs = (ws @ [x]) @- ys @- x ## zs" by simp
  from run_decomp[OF assms[unfolded decomp]] guess by auto
  note decomp_first = this
  from run_sdrop[OF assms, of "length (ws @ [x])"] guess by simp
  moreover from decomp have "sdrop (length ws) xs = ys @- x ## zs"
    by (cases ws; simp add: sdrop_shift)
  ultimately have "run ((ys @ [x]) @- zs)" by simp
  from run_decomp[OF this] guess by clarsimp
  from run_cycle[OF this(1)] decomp_first have
    "run (cycle (ys @ [x]))"
    by (force split: if_split_asm)
  with
    extend_run[of "(ws @ [x])" "if ys = [] then shd (x ## zs) else hd ys" "stl (cycle (ys @ [x]))"]
    decomp_first
  have
    "run ((ws @ [x]) @- cycle (ys @ [x]))"
    apply (simp split: if_split_asm)
    subgoal
      using cycle_Cons[of x "[]", simplified] by auto
    apply (cases ys)
     apply (simp; fail)
    by (simp add: cycle_Cons)
  with decomp show ?thesis
    apply (inst_existentials "tl (ws @ [x])" "(ys @ [x])")
    by (cases ws; force)+
qed

(* XXX Duplication *)
lemma buechi_run_finite_state_set_cycle:
  assumes "run (x\<^sub>0 ## xs)" "alw (ev (holds \<phi>)) (x\<^sub>0 ## xs)"
  shows
  "\<exists> ys zs.
    run (x\<^sub>0 ## ys @- cycle zs) \<and> set ys \<union> set zs \<subseteq> {x\<^sub>0} \<union> sset xs
    \<and> zs \<noteq> [] \<and> (\<exists> x \<in> set zs. \<phi> x)"
proof -
  from run_finite_state_set[OF assms(1)] have "finite (sset (x\<^sub>0 ## xs))" .
  with sset_sfilter[OF \<open>alw (ev _) _\<close>] have "finite (sset (sfilter \<phi> (x\<^sub>0 ## xs)))"
    by (rule finite_subset)
  from finite_sset_sfilter_decomp[OF this assms(2)] obtain x ws ys zs where
    decomp: "x\<^sub>0 ## xs = (ws @ [x]) @- ys @- x ## zs" and "\<phi> x"
    by simp metis
  from run_decomp[OF assms(1)[unfolded decomp]] guess by auto
  note decomp_first = this
  from run_sdrop[OF assms(1), of "length (ws @ [x])"] guess by simp
  moreover from decomp have "sdrop (length ws) xs = ys @- x ## zs"
    by (cases ws; simp add: sdrop_shift)
  ultimately have "run ((ys @ [x]) @- zs)" by simp
  from run_decomp[OF this] guess by clarsimp
  from run_cycle[OF this(1)] decomp_first have
    "run (cycle (ys @ [x]))"
    by (force split: if_split_asm)
  with
    extend_run[of "(ws @ [x])" "if ys = [] then shd (x ## zs) else hd ys" "stl (cycle (ys @ [x]))"]
    decomp_first
  have
    "run ((ws @ [x]) @- cycle (ys @ [x]))"
    apply (simp split: if_split_asm)
    subgoal
      using cycle_Cons[of x "[]", simplified] by auto
    apply (cases ys)
     apply (simp; fail)
    by (simp add: cycle_Cons)
  with decomp \<open>\<phi> x\<close> show ?thesis
    apply (inst_existentials "tl (ws @ [x])" "(ys @ [x])")
    by (cases ws; force)+
qed

lemma run_finite_state_set_cycle_steps:
  assumes "run (x\<^sub>0 ## xs)"
  shows "\<exists> x ys zs. steps (x\<^sub>0 # ys @ x # zs @ [x]) \<and> set ys \<union> set zs \<subseteq> {x\<^sub>0} \<union> sset xs"
proof -
  from run_finite_state_set_cycle[OF assms] guess ys zs by safe
  note guessed = this
  from \<open>zs \<noteq> []\<close> have "cycle zs = (hd zs # tl zs @ [hd zs]) @- cycle (tl zs @ [hd zs])"
    apply (cases zs)
     apply (simp; fail)
    apply simp
    apply (subst cycle_Cons[symmetric])
    apply (subst cycle_decomp)
    by simp+
  from guessed(1)[unfolded this] have
    "run ((x\<^sub>0 # ys @ hd zs # tl zs @ [hd zs]) @- cycle (tl zs @ [hd zs]))"
    by simp
  from run_decomp[OF this] guessed(2,3) show ?thesis
    by (inst_existentials "hd zs" ys "tl zs") (auto dest: list.set_sel(2))
qed

(* XXX Duplication *)
lemma buechi_run_finite_state_set_cycle_steps:
  assumes "run (x\<^sub>0 ## xs)" "alw (ev (holds \<phi>)) (x\<^sub>0 ## xs)"
  shows
  "\<exists> x ys zs.
    steps (x\<^sub>0 # ys @ x # zs @ [x]) \<and> set ys \<union> set zs \<subseteq> {x\<^sub>0} \<union> sset xs \<and> (\<exists> y \<in> set (x # zs). \<phi> y)"
proof -
  from buechi_run_finite_state_set_cycle[OF assms] guess ys zs x by safe
  note guessed = this
  from \<open>zs \<noteq> []\<close> have "cycle zs = (hd zs # tl zs @ [hd zs]) @- cycle (tl zs @ [hd zs])"
    apply (cases zs)
     apply (simp; fail)
    apply simp
    apply (subst cycle_Cons[symmetric])
    apply (subst cycle_decomp)
    by simp+
  from guessed(1)[unfolded this] have
    "run ((x\<^sub>0 # ys @ hd zs # tl zs @ [hd zs]) @- cycle (tl zs @ [hd zs]))"
    by simp
  from run_decomp[OF this] guessed(2,3,4,5) show ?thesis
    by (inst_existentials "hd zs" ys "tl zs") (auto dest: list.set_sel(2))
qed

end (* Finite Graph *)


section \<open>Complete Simulation Graphs\<close>

context Simulation_Graph_Defs
begin

definition "abstract_run x xs = x ## sscan (\<lambda> y a. SOME b. A a b \<and> y \<in> b) xs x"

lemma abstract_run_ctr:
  "abstract_run x xs = x ## abstract_run (SOME b. A x b \<and> shd xs \<in> b) (stl xs)"
  unfolding abstract_run_def by (subst sscan.ctr) (rule HOL.refl)

end

context Simulation_Graph_Complete
begin

lemma steps_complete:
  "\<exists> as. Steps (a # as) \<and> list_all2 (op \<in>) xs as" if "steps (x # xs)" "x \<in> a" "P a"
  using that
  by (induction xs arbitrary: x a) (erule steps.cases; fastforce dest!: complete intro: P_invariant)+

lemma abstract_run_Run:
  "Run (abstract_run a xs)" if "run (x ## xs)" "x \<in> a" "P a"
  using that
proof (coinduction arbitrary: a x xs)
  case (run a x xs)
  obtain y ys where "xs = y ## ys" by (metis stream.collapse)
  with run have "C x y" "run (y ## ys)" by (auto elim: run.cases)
  from complete[OF \<open>C x y\<close> \<open>P a\<close> \<open>x \<in> a\<close>] obtain b where "A a b \<and> y \<in> b" by auto
  then have "A a (SOME b. A a b \<and> y \<in> b) \<and> y \<in> (SOME b. A a b \<and> y \<in> b)" by (rule someI)
  moreover with \<open>P a\<close> have "P (SOME b. A a b \<and> y \<in> b)" by (blast intro: P_invariant)
  ultimately show ?case using \<open>run (y ## ys)\<close> unfolding \<open>xs = _\<close>
    apply (subst abstract_run_ctr, simp)
    apply (subst abstract_run_ctr, simp)
    by (auto simp: abstract_run_ctr[symmetric])
qed

lemma abstract_run_abstract:
  "stream_all2 (op \<in>) (x ## xs) (abstract_run a xs)" if "run (x ## xs)" "x \<in> a" "P a"
using that proof (coinduction arbitrary: a x xs)
  case run: (stream_rel x' u b' v a x xs)
  obtain y ys where "xs = y ## ys" by (metis stream.collapse)
  with run have "C x y" "run (y ## ys)" by (auto elim: run.cases)
  from complete[OF \<open>C x y\<close> \<open>P a\<close> \<open>x \<in> a\<close>] obtain b where "A a b \<and> y \<in> b" by auto
  then have "A a (SOME b. A a b \<and> y \<in> b) \<and> y \<in> (SOME b. A a b \<and> y \<in> b)" by (rule someI)
  with \<open>run (y ## ys)\<close> \<open>x \<in> a\<close> \<open>P a\<close> run(1,2) \<open>xs = _\<close> show ?case
    by (subst (asm) abstract_run_ctr) (auto intro: P_invariant)
qed

lemma run_complete:
  "\<exists> as. Run (a ## as) \<and> stream_all2 (op \<in>) xs as" if "run (x ## xs)" "x \<in> a" "P a"
  using abstract_run_Run[OF that] abstract_run_abstract[OF that]
  apply (subst (asm) abstract_run_ctr)
  apply (subst (asm) (2) abstract_run_ctr)
  by auto

end (* Simulation Graph Complete Abstraction *)


subsection \<open>Runs in Finite Complete Graphs\<close>

context Simulation_Graph_Finite_Complete
begin

lemma run_finite_state_set_cycle_steps:
  assumes "run (x\<^sub>0 ## xs)" "x\<^sub>0 \<in> a\<^sub>0" "P a\<^sub>0"
  shows "\<exists> x ys zs.
    Steps (a\<^sub>0 # ys @ x # zs @ [x]) \<and> (\<forall> a \<in> set ys \<union> set zs. \<exists> x \<in> {x\<^sub>0} \<union> sset xs. x \<in> a)"
  using run_complete[OF assms]
  apply safe
  apply (drule Steps_finite.run_finite_state_set_cycle_steps)
  apply safe
  subgoal for as x ys zs
    apply (inst_existentials x ys zs)
    using assms(2) by (auto dest: stream_all2_sset2)
  done

lemma buechi_run_finite_state_set_cycle_steps:
  assumes "run (x\<^sub>0 ## xs)" "x\<^sub>0 \<in> a\<^sub>0" "P a\<^sub>0" "alw (ev (holds \<phi>)) (x\<^sub>0 ## xs)"
  shows "\<exists> x ys zs.
    Steps (a\<^sub>0 # ys @ x # zs @ [x])
    \<and> (\<forall> a \<in> set ys \<union> set zs. \<exists> x \<in> {x\<^sub>0} \<union> sset xs. x \<in> a)
    \<and> (\<exists> y \<in> set (x # zs). \<exists> a \<in> y. \<phi> a)"
  using run_complete[OF assms(1-3)]
  apply safe
  apply (drule Steps_finite.buechi_run_finite_state_set_cycle_steps[where \<phi> = "\<lambda> S. \<exists> x \<in> S. \<phi> x"])
  subgoal for as
    using assms(4)
    apply (subst alw_ev_stl[symmetric], simp)
    apply (erule alw_stream_all2_mono[where Q = "ev (holds \<phi>)"], fastforce)
    by (metis (mono_tags, lifting) ev_holds_sset stream_all2_sset1)
  apply safe
  subgoal for as x ys zs y a
    apply (inst_existentials x ys zs)
    using assms(2) by (auto dest: stream_all2_sset2)
  done

end (* Simulation Graph Finite Complete Abstraction *)


section \<open>Finite Complete Double Simulations\<close>

context Double_Simulation_Finite_Complete
begin

lemmas P2_invariant_Steps = P2_invariant.invariant_steps

theorem infinite_run_cycle_iff':
  assumes "P2 a\<^sub>0" "\<And> x xs. run (x ## xs) \<Longrightarrow> x \<in> \<Union>closure a\<^sub>0 \<Longrightarrow> \<exists> y ys. y \<in> a\<^sub>0 \<and> run (y ## ys)"
  shows "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> run (x\<^sub>0 ## xs)) \<longleftrightarrow> (\<exists> as a bs. Steps (a\<^sub>0 # as @ a # bs @ [a]))"
proof (safe, goal_cases)
  case (1 x\<^sub>0 xs)
  from run_finite_state_set_cycle_steps[OF this(2,1)] \<open>P2 a\<^sub>0\<close> show ?case by auto
next
  case prems: (2 as a bs)
  with Steps.steps_decomp[of "a\<^sub>0 # as @ [a]" "bs @ [a]"] have "Steps (a\<^sub>0 # as @ [a])" by auto
  from P2_invariant_Steps[OF this] have "P2 a" by auto
  from Steps_run_cycle''[OF prems this] assms(2) show ?case by auto
qed

corollary infinite_run_cycle_iff:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> run (x\<^sub>0 ## xs)) \<longleftrightarrow> (\<exists> as a bs. Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  if "\<Union>closure a\<^sub>0 = a\<^sub>0" "P2 a\<^sub>0"
  by (rule infinite_run_cycle_iff', auto simp: that)

context
  fixes \<phi> :: "'a \<Rightarrow> bool" -- "The property we want to check"
  assumes \<phi>_closure_compatible: "x \<in> a \<Longrightarrow> \<phi> x \<longleftrightarrow> (\<forall> x \<in> \<Union> closure a. \<phi> x)"
begin

theorem infinite_buechi_run_cycle_iff:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> run (x\<^sub>0 ## xs) \<and> alw (ev (holds \<phi>)) (x\<^sub>0 ## xs))
  \<longleftrightarrow> (\<exists> as a bs. Steps (a\<^sub>0 # as @ a # bs @ [a]) \<and> (\<forall> x \<in> \<Union> closure a. \<phi> x))"
  if "\<Union>closure a\<^sub>0 = a\<^sub>0"
proof (safe, goal_cases)
  case (1 x\<^sub>0 xs)
  from buechi_run_finite_state_set_cycle_steps[OF this(2,1) P2_a\<^sub>0, of \<phi>] this(3) guess a ys zs
    by clarsimp
  note guessed = this(2-)
  from guessed(3) show ?case
  proof (standard, goal_cases)
    case 1
    then obtain x where "x \<in> a" "\<phi> x" by auto
    with \<phi>_closure_compatible have "\<forall> x \<in> \<Union> closure a. \<phi> x" by blast
    with guessed(1,2) show ?case by auto
  next
    case 2
    then obtain b x where "x \<in> b" "b \<in> set zs" "\<phi> x" by auto
    with \<phi>_closure_compatible have *: "\<forall> x \<in> \<Union> closure b. \<phi> x" by blast
    from \<open>b \<in> set zs\<close> obtain zs1 zs2 where "zs = zs1 @ b # zs2" by (force simp: split_list)
    with guessed(1) have "Steps ((a\<^sub>0 # ys) @ (a # zs1 @ [b]) @ zs2 @ [a])" by simp
    then have "Steps (a # zs1 @ [b])" by (blast dest!: Steps.steps_decomp)
    with \<open>zs = _\<close> guessed * show ?case
      apply (inst_existentials "ys @ a # zs1" b "zs2 @ a # zs1")
      using Steps.steps_append[of "a\<^sub>0 # ys @ a # zs1 @ b # zs2 @ [a]" "a # zs1 @ [b]"]
      by auto
  qed
next
  case prems: (2 as a bs)
  with Steps.steps_decomp[of "a\<^sub>0 # as @ [a]" "bs @ [a]"] have "Steps (a\<^sub>0 # as @ [a])" by auto
  from P2_invariant_Steps[OF this] have "P2 a" by auto
  from Steps_run_cycle''[OF prems(1) this] prems this that show ?case
    apply safe
    subgoal for x xs b
      unfolding HLD_iff by (inst_existentials x xs) (auto intro: alw_ev_mono) (* Slow *)
    done
qed

end (* Context for Fixed Formula *)

end (* Double Simulation Finite Complete Abstraction *)


section \<open>Encoding of Properties in Runs\<close>

text \<open>
  This approach only works if we assume strong compatibility of the property.
  For weak compatibility, encoding in the automaton is likely the right way.
\<close>

context Double_Simulation_Finite_Complete_Abstraction_Prop
begin

definition "C_\<phi> x y \<equiv> C x y \<and> \<phi> y"
definition "A1_\<phi> a b \<equiv> A1 a b \<and> b \<subseteq> {x. \<phi> x}"
definition "A2_\<phi> S S' \<equiv> \<exists> S''. A2 S S'' \<and> S'' \<inter> {x. \<phi> x} = S' \<and> S' \<noteq> {}"

lemma A2_\<phi>_P2_invariant:
  "P2 a" if "A2_\<phi>\<^sup>*\<^sup>* a\<^sub>0 a"
proof -
  interpret invariant: Graph_Invariant_Start A2_\<phi> a\<^sub>0 P2
    by standard (auto intro: \<phi>_P2_compatible P2_invariant P2_a\<^sub>0 simp: A2_\<phi>_def)
  from invariant.invariant_reaches[OF that] show ?thesis .
qed

sublocale phi: Double_Simulation_Finite_Complete C_\<phi> A1_\<phi> P1 A2_\<phi> P2 a\<^sub>0
proof (standard, goal_cases)
  case (1 S T)
  then show ?case unfolding A1_\<phi>_def C_\<phi>_def by (auto 4 4 dest: \<phi>_A1_compatible prestable)
next
  case (2 y b a)
  then obtain c where "A2 a c" "c \<inter> {x. \<phi> x} = b" unfolding A2_\<phi>_def by auto
  with \<open>y \<in> _\<close> have "y \<in> closure c" by (auto dest: closure_intD)
  moreover have "y \<subseteq> {x. \<phi> x}"
    by (smt "2"(1) \<phi>_A1_compatible \<open>A2 a c\<close> \<open>c \<inter> {x. \<phi> x} = b\<close> \<open>y \<in> closure c\<close> closure_def
        closure_poststable inf_assoc inf_bot_right inf_commute mem_Collect_eq)
  ultimately show ?case using \<open>A2 a c\<close> unfolding A1_\<phi>_def A2_\<phi>_def
    by (auto dest: closure_poststable)
next
  case (3 x y)
  then show ?case by (rule P1_distinct)
next
  case 4
  then show ?case by (rule P1_finite)
next
  case (5 a)
  then show ?case by (rule P2_cover)
next
  case (6 x y S)
  then show ?case unfolding C_\<phi>_def A2_\<phi>_def by (auto dest!: complete)
next
  case 7
  have "{a. A2_\<phi>\<^sup>*\<^sup>* a\<^sub>0 a} \<subseteq> {a. Steps.reaches a\<^sub>0 a}"
    apply safe
    subgoal premises prems for x
        using prems
        proof (induction x1 \<equiv> a\<^sub>0 x rule: rtranclp.induct)
          case rtrancl_refl
          then show ?case by blast
        next
          case prems: (rtrancl_into_rtrancl b c)
          then have "c \<noteq> {}"
            by - (rule P2_non_empty, auto intro: A2_\<phi>_P2_invariant)
          from \<open>A2_\<phi> b c\<close> obtain S'' x where
            "A2 b S''" "c = S'' \<inter> {x. \<phi> x}" "x \<in> S''" "\<phi> x"
            unfolding A2_\<phi>_def by auto
          with prems \<open>c \<noteq> {}\<close> \<phi>_A2_compatible[of S''] show ?case
            including graph_automation_aggressive by auto
        qed
    done
  then show ?case (is "finite ?S") using finite_abstract_reachable by (rule finite_subset)
next
  case (8 a a')
  then show ?case unfolding A2_\<phi>_def by (auto intro: P2_invariant \<phi>_P2_compatible)
next
  case 9
  then show ?case by (rule P2_a\<^sub>0)
qed

lemma phi_run_iff:
  "phi.run (x ## xs) \<and> \<phi> x \<longleftrightarrow> run (x ## xs) \<and> pred_stream \<phi> (x ## xs)"
proof -
  have "phi.run xs" if "run xs" "pred_stream \<phi> xs" for xs
    using that by (coinduction arbitrary: xs) (auto elim: run.cases simp: C_\<phi>_def)
  moreover have "run xs" if "phi.run xs" for xs
    using that by (coinduction arbitrary: xs) (auto elim: phi.run.cases simp: C_\<phi>_def)
  moreover have "pred_stream \<phi> xs" if "phi.run (x ## xs)" "\<phi> x"
    using that by (coinduction arbitrary: xs x) (auto 4 3 elim: phi.run.cases simp: C_\<phi>_def)
  ultimately show ?thesis by auto
qed

corollary infinite_run_cycle_iff:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> run (x\<^sub>0 ## xs) \<and> pred_stream \<phi> (x\<^sub>0 ## xs)) \<longleftrightarrow>
   (\<exists> as a bs. phi.Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  if "\<Union>closure a\<^sub>0 = a\<^sub>0" "a\<^sub>0 \<subseteq> {x. \<phi> x}"
  unfolding phi.infinite_run_cycle_iff[OF that(1) P2_a\<^sub>0, symmetric] phi_run_iff[symmetric]
  using that(2) by auto

theorem Alw_ev_mc:
  "(\<forall> x\<^sub>0 \<in> a\<^sub>0. Alw_ev (Not o \<phi>) x\<^sub>0) \<longleftrightarrow> \<not> (\<exists> as a bs. phi.Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  if "\<Union>closure a\<^sub>0 = a\<^sub>0" "a\<^sub>0 \<subseteq> {x. \<phi> x}"
  unfolding Alw_ev alw_holds_pred_stream_iff infinite_run_cycle_iff[OF that, symmetric]
  by (auto simp: comp_def)

end (* Double Simulation Finite Complete Abstraction Prop *)

context Simulation_Graph_Defs
begin

definition "represent_run x as = x ## sscan (\<lambda> b x. SOME y. C x y \<and> y \<in> b) as x"

lemma represent_run_ctr:
  "represent_run x as = x ## represent_run (SOME y. C x y \<and> y \<in> shd as) (stl as)"
  unfolding represent_run_def by (subst sscan.ctr) (rule HOL.refl)

end (* Simulation Graph Defs *)

context Simulation_Graph_Prestable
begin

lemma represent_run_Run:
  "run (represent_run x as)" if "Run (a ## as)" "x \<in> a"
using that
proof (coinduction arbitrary: a x as)
  case (run a x as)
  obtain b bs where "as = b ## bs" by (metis stream.collapse)
  with run have "A a b" "Run (b ## bs)" by (auto elim: Steps.run.cases)
  from prestable[OF \<open>A a b\<close>] \<open>x \<in> a\<close> obtain y where "C x y \<and> y \<in> b" by auto
  then have "C x (SOME y. C x y \<and> y \<in> b) \<and> (SOME y. C x y \<and> y \<in> b) \<in> b" by (rule someI)
  then show ?case using \<open>Run (b ## bs)\<close> unfolding \<open>as = _\<close>
    apply (subst represent_run_ctr, simp)
    apply (subst represent_run_ctr, simp)
    by (auto simp: represent_run_ctr[symmetric])
qed

lemma represent_run_represent:
  "stream_all2 (op \<in>) (represent_run x as) (a ## as)" if "Run (a ## as)" "x \<in> a"
using that
proof (coinduction arbitrary: a x as)
  case (stream_rel x' xs a' as' a x as)
  obtain b bs where "as = b ## bs" by (metis stream.collapse)
  with stream_rel have "A a b" "Run (b ## bs)" by (auto elim: Steps.run.cases)
  from prestable[OF \<open>A a b\<close>] \<open>x \<in> a\<close> obtain y where "C x y \<and> y \<in> b" by auto
  then have "C x (SOME y. C x y \<and> y \<in> b) \<and> (SOME y. C x y \<and> y \<in> b) \<in> b" by (rule someI)
  with \<open>x' ## xs = _\<close> \<open>a' ## as' = _\<close> \<open>x \<in> a\<close> \<open>Run (b ## bs)\<close> show ?case unfolding \<open>as = _\<close>
    by (subst (asm) represent_run_ctr) auto
qed

end (* Simulation Graph Prestable *)

(* XXX Move *)
theorem stream_all2_SCons1:
  fixes P :: "'b \<Rightarrow> 'c \<Rightarrow> bool"
    and x :: "'b"
    and xs :: "'b stream"
    and ys :: "'c stream"
  shows "stream_all2 P (x ## xs) ys = (\<exists>z zs. ys = z ## zs \<and> P x z \<and> stream_all2 P xs zs)"
  by (subst (3) stream.collapse[symmetric], simp del: stream.collapse, force)

(* XXX Move *)
theorem stream_all2_SCons2:
  fixes P :: "'b \<Rightarrow> 'c \<Rightarrow> bool"
    and xs :: "'b stream"
    and y :: "'c"
    and ys :: "'c stream"
  shows "stream_all2 P xs (y ## ys) = (\<exists>z zs. xs = z ## zs \<and> P z y \<and> stream_all2 P zs ys)"
    by (subst stream.collapse[symmetric], simp del: stream.collapse, force)

lemma stream_all2_shift1:
  "stream_all2 P (xs1 @- xs2) ys =
  (\<exists> ys1 ys2. ys = ys1 @- ys2 \<and> list_all2 P xs1 ys1 \<and> stream_all2 P xs2 ys2)"
  apply (induction xs1 arbitrary: ys)
   apply (simp; fail)
  apply (simp add: stream_all2_SCons1 list_all2_Cons1)
  apply safe
  subgoal for a xs1 ys z zs ys1 ys2
    by (inst_existentials "z # ys1" ys2; simp)
  subgoal for a xs1 ys ys1 ys2 z zs
    by (inst_existentials z "zs @- ys2" zs "ys2"; simp)
  done

lemma stream_all2_shift2:
  "stream_all2 P ys (xs1 @- xs2) =
  (\<exists> ys1 ys2. ys = ys1 @- ys2 \<and> list_all2 P ys1 xs1 \<and> stream_all2 P ys2 xs2)"
  by (meson list.rel_flip stream.rel_flip stream_all2_shift1)

(* XXX Move *)
lemma stream_all2_bisim:
  assumes "stream_all2 op \<in> xs as" "stream_all2 op \<in> ys as" "sset as \<subseteq> S"
  shows "stream_all2 (\<lambda> x y. \<exists> a. x \<in> a \<and> y \<in> a \<and> a \<in> S) xs ys"
  using assms
  apply (coinduction arbitrary: as xs ys)
  subgoal for a u b v as xs ys
    apply (rule conjI)
     apply (inst_existentials "shd as", auto simp: stream_all2_SCons1; fail)
    apply (inst_existentials "stl as", auto 4 3 simp: stream_all2_SCons1; fail)
    done
  done

context Simulation_Graph_Complete_Prestable
begin

lemma runs_bisim:
  "\<exists> ys. run (y ## ys) \<and> stream_all2 (\<lambda> x y. \<exists> a. x \<in> a \<and> y \<in> a \<and> P a) xs ys"
  if "run (x ## xs)" "x \<in> a" "y \<in> a" "P a"
proof -
  define f where "f a x = (SOME b. A a b \<and> x \<in> b)" for a x
  let ?as = "abstract_run (f a (shd xs)) (stl xs)"
  from abstract_run_Run abstract_run_abstract that have
    "Run (abstract_run a xs)" "stream_all2 (op \<in>) (x ## xs) (abstract_run a xs)"
    by blast+
  with abstract_run_ctr[of a xs] have "Run (a ## ?as)"
    by (auto simp: f_def)
  then have "pred_stream P ?as"
    by - (drule invariant_run, rule \<open>P a\<close>, auto intro: P_invariant)
  from
    represent_run_Run[OF \<open>Run (a ## _)\<close> \<open>y \<in> a\<close>] represent_run_represent[OF \<open>Run (a ## _)\<close> \<open>y \<in> a\<close>]
  have
    "run (represent_run y ?as)" "stream_all2 op \<in> (represent_run y ?as) (a ## ?as)" .
  with \<open>stream_all2 op \<in> (x ## xs) _\<close> have
    "stream_all2 (\<lambda>x y. \<exists>a. x \<in> a \<and> y \<in> a \<and> a \<in> sset ?as) xs (stl (represent_run y ?as))"
    apply -
    apply (rule stream_all2_bisim)
      apply (subst (asm) abstract_run_ctr, force)
     apply (subst (asm) (2) represent_run_ctr, subst represent_run_ctr, simp add: f_def)
    by (auto simp: f_def)
  then have "stream_all2 (\<lambda>x y. \<exists>a. x \<in> a \<and> y \<in> a \<and> P a) xs (stl (represent_run y ?as))"
    apply (rule stream.rel_mono_strong)
    using \<open>pred_stream P _\<close> by (auto simp: stream.pred_set)
  with \<open>run (represent_run y ?as)\<close> show ?thesis
    using \<open>stream_all2 (op \<in>) (x ## xs) _\<close>
    apply (intro exI conjI)
     apply (subst (asm) represent_run_ctr)
     apply assumption
    apply (subst (asm) (2) represent_run_ctr, simp; fail)
    done
qed

lemma runs_bisim':
  "\<exists> ys. run (y ## ys)" if "run (x ## xs)" "x \<in> a" "y \<in> a" "P a"
  using runs_bisim[OF that] by blast

context
  fixes Q :: "'a \<Rightarrow> bool"
  assumes compatible: "Q x \<Longrightarrow> x \<in> a \<Longrightarrow> y \<in> a \<Longrightarrow> P a \<Longrightarrow> Q y"
begin

lemma Alw_ev_compatible':
  assumes "\<forall>xs. run (x ## xs) \<longrightarrow> ev (holds Q) (x ## xs)" "run (y ## xs)" "x \<in> a" "y \<in> a" "P a"
  shows "ev (holds Q) (y ## xs)"
proof -
  let ?f = \<open>\<lambda>x y. \<exists>a. x \<in> a \<and> y \<in> a \<and> P a\<close>
  from runs_bisim[OF assms(2) \<open>y \<in> a\<close> \<open>x \<in> a\<close> \<open>P a\<close>] obtain ys where
    "run (x ## ys)" "stream_all2 ?f xs ys"
    by auto
  with assms(1) have "ev (holds Q) (x ## ys)"
    by auto
  show ?thesis
  proof (cases "Q x")
    case True
    with \<open>y \<in> a\<close> \<open>x \<in> a\<close> \<open>P a\<close> have "Q y"
      by (auto intro: compatible)
    then show ?thesis
      by auto
  next
    case False
    from False \<open>ev (holds Q) (x ## ys)\<close> have \<open>ev (holds Q) ys\<close>
      by (simp add: ev_Stream)
    from ev_imp_shift[OF this] obtain x1 ys1 ys2 where
      "ys = ys1 @- x1 ## ys2" "Q x1"
      apply clarsimp
        using stream.collapse by metis
    with \<open>stream_all2 _ _ _\<close> obtain y1 xs1 xs2 where
      "xs = xs1 @- y1 ## xs2" "?f x1 y1"
      by (auto simp: stream_all2_shift2 stream_all2_SCons2)
    with \<open>Q x1\<close> have "Q y1"
      by (auto intro: compatible)
    with \<open>xs = _\<close> show ?thesis
      by (simp add: ev_Stream ev_shift)
  qed
qed

lemma Alw_ev_compatible:
  "Alw_ev Q x \<longleftrightarrow> Alw_ev Q y" if "x \<in> a" "y \<in> a" "P a"
  unfolding Alw_ev_def using that by (auto intro: Alw_ev_compatible')

end (* Context for Compatibility *)

lemma steps_bisim:
  "\<exists> ys. steps (y # ys) \<and> list_all2 (\<lambda> x y. \<exists> a. x \<in> a \<and> y \<in> a \<and> P a) xs ys"
  if "steps (x # xs)" "x \<in> a" "y \<in> a" "P a"
  using \<open>y \<in> a\<close> steps_complete[OF that(1,2,4)]
  apply clarify
  apply (frule Steps_prestable)
   apply simp
  apply clarify
  apply (intro exI conjI)
   apply assumption
  subgoal premises prems for as xs'
    using prems(3,6) invariant_steps[OF prems(2) \<open>P a\<close>]
    by (induction as arbitrary: xs') (auto simp: list_all2_Cons2)
  done

end (* Simulation Graph Complete Prestable *)

context Double_Simulation_Finite_Complete_Abstraction_Prop_Bisim
begin

sublocale Simulation_Graph_Complete_Prestable C_\<phi> A1_\<phi> P1
  by (standard; force dest: P1_invariant \<phi>_A1_compatible A1_complete simp: C_\<phi>_def A1_\<phi>_def)

lemma runs_closure_bisim:
  "\<exists>y ys. y \<in> a\<^sub>0 \<and> phi.run (y ## ys)" if "phi.run (x ## xs)" "x \<in> \<Union>phi.closure a\<^sub>0"
  using that(2) runs_bisim'[OF that(1)] unfolding phi.closure_def by auto

lemma infinite_run_cycle_iff':
  "(\<exists>x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> phi.run (x\<^sub>0 ## xs)) = (\<exists>as a bs. phi.Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  by (intro phi.infinite_run_cycle_iff' P2_a\<^sub>0 runs_closure_bisim)

corollary infinite_run_cycle_iff:
  "(\<exists> x\<^sub>0 xs. x\<^sub>0 \<in> a\<^sub>0 \<and> run (x\<^sub>0 ## xs) \<and> pred_stream \<phi> (x\<^sub>0 ## xs)) \<longleftrightarrow>
   (\<exists> as a bs. phi.Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  if "a\<^sub>0 \<subseteq> {x. \<phi> x}"
  unfolding infinite_run_cycle_iff'[symmetric] phi_run_iff[symmetric] using that by auto

theorem Alw_ev_mc:
  "(\<forall> x\<^sub>0 \<in> a\<^sub>0. Alw_ev (Not o \<phi>) x\<^sub>0) \<longleftrightarrow> \<not> (\<exists> as a bs. phi.Steps (a\<^sub>0 # as @ a # bs @ [a]))"
  if "a\<^sub>0 \<subseteq> {x. \<phi> x}"
  unfolding Alw_ev alw_holds_pred_stream_iff infinite_run_cycle_iff[OF that, symmetric]
  by (auto simp: comp_def)

end (* Double Simulation Finite Complete Abstraction Prop *)

context Double_Simulation_Finite_Complete_Bisim_Cover
begin

lemma P2_closure_subs:
  "a \<subseteq> \<Union> closure a" if "P2 a"
  using P2_P1_cover[OF that] unfolding closure_def by auto

lemma (in Double_Simulation_Finite_Complete) P2_Steps_last:
  "P2 (last as)" if "Steps as" "a\<^sub>0 = hd as"
  using that by - (cases as, auto dest!: P2_invariant_Steps simp: list_all_iff P2_a\<^sub>0)

context
  fixes P
  assumes P1_P: "\<And> a x y. x \<in> a \<Longrightarrow> y \<in> a \<Longrightarrow> P1 a \<Longrightarrow> P x \<longleftrightarrow> P y"
begin

lemma reaches_all_1:
  fixes b :: "'a set" and y :: "'a" and as :: "'a set list"
  assumes A: "\<forall>y. (\<exists>x\<^sub>0\<in>\<Union>closure (hd as). \<exists>xs. hd xs = x\<^sub>0 \<and> last xs = y \<and> steps xs) \<longrightarrow> P y"
     and "y \<in> last as" and "a\<^sub>0 = hd as" and "Steps as"
  shows "P y"
proof -
  from assms obtain bs where [simp]: "as = a\<^sub>0 # bs" by (cases as) auto
  from Steps_Union[OF \<open>Steps _\<close>] have "post_defs.Steps (map closure as)" .
  from \<open>Steps as\<close> \<open>a\<^sub>0 = _\<close> have "P2 (last as)"
    by (rule P2_Steps_last)
  obtain b2 where b2: "y \<in> b2" "b2 \<in> last (closure a\<^sub>0 # map closure bs)"
    apply atomize_elim
    apply simp
    apply safe
    using \<open>y \<in> _\<close> P2_closure_subs[OF \<open>P2 (last as)\<close>]
    by (auto simp: last_map)
  with post.Steps_poststable[OF \<open>post_defs.Steps _\<close>, of b2] obtain as' where as':
    "pre_defs.Steps as'" "list_all2 op \<in> as' (closure a\<^sub>0 # map closure bs)" "last as' = b2"
    by auto
  then obtain x\<^sub>0 where "x\<^sub>0 \<in> hd as'"
    by (cases as') (auto split: if_split_asm simp: closure_def)
  from pre.Steps_prestable[OF \<open>pre_defs.Steps _\<close> \<open>x\<^sub>0 \<in> _\<close>] obtain xs where
    "steps (x\<^sub>0 # xs)" "list_all2 op \<in> (x\<^sub>0 # xs) as'"
    by auto
  from \<open>x\<^sub>0 \<in> _\<close> \<open>list_all2 op \<in> as' _\<close> have "x\<^sub>0 \<in> \<Union> closure a\<^sub>0"
    by (cases as') auto
  with A \<open>steps _\<close> have "P (last (x\<^sub>0 # xs))"
    by fastforce
  from as' have "P1 b2"
    using b2 by (auto simp: closure_def last_map split: if_split_asm)
  from \<open>list_all2 op \<in> as' _\<close> \<open>list_all2 op \<in> _ as'\<close> \<open>_ = b2\<close> have "last (x\<^sub>0 # xs) \<in> b2"
     by (fastforce dest!: list_all2_last)
  from P1_P[OF this \<open>y \<in> b2\<close> \<open>P1 b2\<close>] \<open>P _\<close> show "P y" ..
qed

lemma reaches_all_2:
  fixes x\<^sub>0 a xs
  assumes A: "\<forall>b y. (\<exists>xs. hd xs = a\<^sub>0 \<and> last xs = b \<and> Steps xs) \<and> y \<in> b \<longrightarrow> P y"
    and "hd xs \<in> a" and "a \<in> closure a\<^sub>0" and "steps xs"
  shows "P (last xs)"
proof -
  {
    fix y x\<^sub>0 xs
    assume "hd xs \<in> a\<^sub>0" and "steps xs"
    then obtain x ys where [simp]: "xs = x # ys" "x \<in> a\<^sub>0" by (cases xs) auto
    from steps_complete[of x ys a\<^sub>0] \<open>steps xs\<close> P2_a\<^sub>0 obtain as where
      "Steps (a\<^sub>0 # as)" "list_all2 op \<in> ys as"
      by auto
    then have "last xs \<in> last (a\<^sub>0 # as)"
      by (fastforce dest: list_all2_last)
    with A \<open>Steps _\<close> \<open>x \<in> _\<close> have "P (last xs)"
      by (force split: if_split_asm)
  } note * = this
  from \<open>a \<in> closure a\<^sub>0\<close> obtain x where x: "x \<in> a" "x \<in> a\<^sub>0" "P1 a"
    by (auto simp: closure_def)
  with \<open>hd xs \<in> a\<close> \<open>steps xs\<close> bisim.steps_bisim[of "hd xs" "tl xs" a x] obtain xs' where
    "hd xs' = x" "steps xs'" "list_all2 (\<lambda> x y. \<exists> a. x \<in> a \<and> y \<in> a \<and> P1 a) xs xs'"
    apply atomize_elim
    apply clarsimp
    subgoal for ys
      by (inst_existentials "x # ys"; force simp: list_all2_Cons2)
    done
  with *[of xs'] x have "P (last xs')"
    by auto
  from \<open>steps xs\<close> \<open>list_all2 _ xs xs'\<close> obtain b where "last xs \<in> b" "last xs' \<in> b" "P1 b"
    by atomize_elim (fastforce dest!: list_all2_last)
  from P1_P[OF this] \<open>P (last xs')\<close> show "P (last xs)" ..
qed

lemma reaches_all:
  "(\<forall> y. (\<exists> x\<^sub>0\<in>\<Union>closure a\<^sub>0. reaches x\<^sub>0 y) \<longrightarrow> P y) \<longleftrightarrow> (\<forall> b y. Steps.reaches a\<^sub>0 b \<and> y \<in> b \<longrightarrow> P y)"
  unfolding reaches_steps_iff Steps.reaches_steps_iff using reaches_all_1 reaches_all_2 by auto

end (* Locale for Compatibility *)

lemma (in -)
  assumes "\<And> x y a. P x \<Longrightarrow> x \<in> a \<Longrightarrow> y \<in> a \<Longrightarrow> P1 a \<Longrightarrow> P y"
  shows "\<And> a x y. x \<in> a \<Longrightarrow> y \<in> a \<Longrightarrow> P1 a \<Longrightarrow> P x \<longleftrightarrow> P y"
    by (auto intro: assms)

lemma (in Double_Simulation_Defs)
  assumes compatible: "\<And> x y a. P x \<Longrightarrow> x \<in> a \<Longrightarrow> y \<in> a \<Longrightarrow> P1 a \<Longrightarrow> P y"
    and that: "\<forall> x \<in> a. P x"
  shows "\<forall> x \<in> \<Union> closure a. P x"
  using that unfolding closure_def by (auto dest: compatible)

end (* Double Simulation *)

section \<open>Comments\<close>

text \<open>
\<^item> Pre-stability can easily be extended to infinite runs (see construction with @{term sscan} above)
\<^item> Post-stability can not
\<^item> Pre-stability + Completeness means that for every two concrete states in the same abstract class,
  there are equivalent runs
\<^item> For Büchi properties, the predicate has to be compatible with whole closures instead of single
  \<open>P1\<close>-states. This is because for a finite graph where every node has at least indegree one,
  we cannot necessarily conclude that there is a cycle through \<^emph>\<open>every\<close> node.
\<^item> Can offer representation view via suitable locale instantiations?
\<^item> Abstractions view?
\<^item> \<open>\<phi>\<close>-construction can be done on an automaton too (also for disjunctions)
\<^item> Büchi properties are nothing but \<open>\<box>\<diamond>\<close>-properties (@{term \<open>alw (ev \<phi>)\<close>}
\<close>

end (* Theory *)