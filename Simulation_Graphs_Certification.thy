theory Simulation_Graphs_Certification
  imports Subsumption_Graphs
begin

section \<open>Certification Theorems Based on Subsumption and Simulation Graphs\<close>

subsection \<open>Reachability and Over-approximation\<close>

context
  fixes E :: "'a \<Rightarrow> 'a \<Rightarrow> bool" and P :: "'a \<Rightarrow> bool"
    and less_eq :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<preceq>" 50) and less (infix "\<prec>" 50)
  assumes preorder: "class.preorder less_eq less"
  assumes mono: "a \<preceq> b \<Longrightarrow> E a a' \<Longrightarrow> P a \<Longrightarrow> P b \<Longrightarrow> \<exists> b'. E b b' \<and> a' \<preceq> b'"
  assumes invariant: "P a \<Longrightarrow> E a a' \<Longrightarrow> P b"
begin

interpretation preorder less_eq less
  by (rule preorder)

interpretation Simulation_Invariant
  E "\<lambda> x y. \<exists> z. z \<preceq> y \<and> E x z \<and> P z" "(\<preceq>)" P P
  by standard (auto 0 4 intro: invariant dest: mono)

context
  fixes F :: "'a \<Rightarrow> bool" \<comment> \<open>Final states\<close>
  assumes F_mono[intro]: "F a \<Longrightarrow> a \<preceq> b \<Longrightarrow> F b"
begin

corollary reachability_correct:
  "\<nexists> s'. A.reaches a s' \<and> F s'" if "\<nexists> s'. B.reaches b s' \<and> F s'" "a \<preceq> b" "P a" "P b"
  using that by (auto dest!: simulation_reaches)

end (* Context for property *)

end (* Context for over-approximation *)


context Simulation_Invariant
begin

context
  fixes F :: "'a \<Rightarrow> bool" and F' :: "'b \<Rightarrow> bool" \<comment> \<open>Final states\<close>
  assumes F_mono[intro]: "F a \<Longrightarrow> a \<sim> b \<Longrightarrow> F' b"
begin

corollary reachability_correct:
  "\<nexists> s'. A.reaches a s' \<and> F s'" if "\<nexists> s'. B.reaches b s' \<and> F' s'" "a \<sim> b" "PA a" "PB b"
  using that by (auto dest!: simulation_reaches)

end (* Context for property *)

end (* Simulation Invariant *)

subsection \<open>Invariants for Un-reachability\<close>

locale Unreachability_Invariant = Subsumption_Graph_Pre_Defs + preorder less_eq less +
  fixes s\<^sub>0
  fixes S :: "'a set"
  assumes mono:
    "s \<preceq> s' \<Longrightarrow> s \<rightarrow> t \<Longrightarrow> s \<in> S \<or> reaches s\<^sub>0 s \<Longrightarrow> s' \<in> S \<or> reaches s\<^sub>0 s'
  \<Longrightarrow> \<exists> t'. t \<preceq> t' \<and> s' \<rightarrow> t'"
  assumes S_E_subsumed: "s \<in> S \<Longrightarrow> s \<rightarrow> t \<Longrightarrow> \<exists> t' \<in> S. t \<preceq> t'"
begin

lemma reachable_S_subsumed:
  "\<exists> s'. s' \<in> S \<and> s \<preceq> s'" if "s' \<in> S" "s\<^sub>0 \<preceq> s'" "reaches s\<^sub>0 s"
  supply [intro] = order_trans less_trans less_imp_le
  using that(3) apply induction
  subgoal
    using that(1,2) by blast
  apply clarify
  apply (drule mono)
  using S_E_subsumed by blast+

context
  fixes F :: "'a \<Rightarrow> bool" \<comment> \<open>Final states\<close>
  assumes F_mono[intro]: "F a \<Longrightarrow> a \<preceq> b \<Longrightarrow> F b"
begin

corollary final_unreachable:
  "\<nexists> s'. reaches s\<^sub>0 s' \<and> F s'" if "s' \<in> S" "s\<^sub>0 \<preceq> s'" "\<forall> s' \<in> S. \<not> F s'"
  using that by (auto 4 3 dest: reachable_S_subsumed)

end (* Context for property *)

end (* Unreachability Invariant *)

locale Reachability_Invariant_paired_defs =
  ord less_eq less for less_eq :: "'s \<Rightarrow> 's \<Rightarrow> bool" (infix "\<preceq>" 50) and less (infix "\<prec>" 50) +
  fixes E :: "('l \<times> 's) \<Rightarrow> ('l \<times> 's) \<Rightarrow> bool"
  fixes M :: "'l \<Rightarrow> 's set"
    and L :: "'l set" 
  fixes l\<^sub>0 :: 'l and s\<^sub>0 :: 's
begin

definition "covered \<equiv> \<lambda> (l, s). \<exists> s' \<in> M l. s \<prec> s'"

definition "RE = (\<lambda>(l, s) ab. s \<in> M l \<and> \<not> covered (l, s) \<and> E (l, s) ab)"

end (* Reachability Invariant paired defs *)

locale Unreachability_Invariant_paired_pre =
  Reachability_Invariant_paired_defs _ _ E +
  preorder less_eq less for E :: "('l \<times> 's) \<Rightarrow> _" +
  fixes P :: "('l \<times> 's) \<Rightarrow> bool"
  assumes mono:
    "s \<preceq> s' \<Longrightarrow> E (l, s) (l', t) \<Longrightarrow> P (l, s) \<Longrightarrow> P (l, s') \<Longrightarrow> \<exists> t'. t \<preceq> t' \<and> E (l, s') (l', t')"
  assumes P_invariant: "P (l, s) \<Longrightarrow> E (l, s) (l', s') \<Longrightarrow> P (l', s')"

locale Unreachability_Invariant_paired =
  Unreachability_Invariant_paired_pre +
  assumes M_invariant: "l \<in> L \<Longrightarrow> s \<in> M l \<Longrightarrow> P (l, s)"
  assumes start: "l\<^sub>0 \<in> L" "\<exists> s' \<in> M l\<^sub>0. s\<^sub>0 \<preceq> s'" "P (l\<^sub>0, s\<^sub>0)"
  assumes closed:
    "\<forall> l \<in> L. \<forall> s \<in> M l. \<forall>l' s'. E (l, s) (l', s') \<longrightarrow> l' \<in> L \<and> (\<exists> s'' \<in> M l'. s' \<preceq> s'')"
begin

interpretation P_invariant: Graph_Invariant E P
  by standard (auto intro: P_invariant)

interpretation Unreachability_Invariant
  "\<lambda> (l, s) (l', s'). l' = l \<and> s \<preceq> s'" "\<lambda> (l, s) (l', s'). l' = l \<and> s \<prec> s'" E "(l\<^sub>0, s\<^sub>0)"
  "{(l, s) | l s. l \<in> L \<and> s \<in> M l}"
  supply [intro] = order_trans less_trans less_imp_le
  apply standard
      apply (auto simp: less_le_not_le; fail)+
   apply (fastforce intro: P_invariant.invariant_reaches[OF _ start(3)] M_invariant dest: mono)
  using closed by fastforce

context
begin

private definition
  "s' \<equiv> SOME s. s \<in> M l\<^sub>0 \<and> s\<^sub>0 \<preceq> s"

private lemma s'_correct:
  "s' \<in> M l\<^sub>0 \<and> s\<^sub>0 \<preceq> s'"
  using start(2) unfolding s'_def by - (rule someI_ex, auto)

private lemma s'_1:
  "(l\<^sub>0, s') \<in> {(l, s) |l s. l \<in> L \<and> s \<in> M l}"
  using s'_correct start by auto

private lemma s'_2:
  "(case (l\<^sub>0, s\<^sub>0) of (l, s) \<Rightarrow> \<lambda>(l', s'). l' = l \<and> s \<preceq> s') (l\<^sub>0, s')"
  using s'_correct start by auto

lemmas final_unreachable = final_unreachable[OF _ s'_1 s'_2]

end (* Anonymous Context *)

thm final_unreachable

end (* Unreachability Invariant paired *)

subsection \<open>Instantiating Reachability Compatible Subsumption Graphs\<close>

locale Reachability_Invariant_paired = Reachability_Invariant_paired_defs + preorder less_eq less +
  assumes E_T: "\<forall> l s l' s'. E (l, s) (l', s') \<longleftrightarrow> (\<exists> f. (l', f) \<in> T l \<and> s' = f s)"
  assumes mono:
    "s \<preceq> s' \<Longrightarrow> E (l, s) (l', t) \<Longrightarrow> E\<^sup>*\<^sup>* (l\<^sub>0, s\<^sub>0) (l, s) \<Longrightarrow> E\<^sup>*\<^sup>* (l\<^sub>0, s\<^sub>0) (l, s')
    \<Longrightarrow> \<exists> t'. t \<preceq> t' \<and> E (l, s') (l', t')"
  assumes finitely_branching: "finite (Collect (E (a, b)))"
  assumes start:"l\<^sub>0 \<in> L" "s\<^sub>0 \<in> S" "s\<^sub>0 \<in> M(l\<^sub>0)"
  assumes closed:
    "\<forall> l \<in> L. \<forall> (l', f) \<in> T l. l' \<in> L \<and> (\<forall> s \<in> M l. (\<exists> s' \<in> M l'. f s \<prec> s') \<or> f s \<in> M l')"
  assumes reachable:
    "\<forall> l \<in> L. \<forall> s \<in> M l. RE\<^sup>*\<^sup>* (l\<^sub>0, s\<^sub>0) (l, s)"
  assumes finite:
    "finite L" "\<forall> l \<in> L. finite (M l)"
begin

lemma invariant:
  "((\<exists> s' \<in> M l. s \<prec> s') \<or> s \<in> M l) \<and> l \<in> L" if "RE\<^sup>*\<^sup>* (l\<^sub>0, s\<^sub>0) (l, s)"
  using that start closed by (induction rule: rtranclp_induct2) (auto 4 3 simp: RE_def)

interpretation Reachability_Compatible_Subsumption_Graph_View 
  "\<lambda> (l, s) (l', s'). l' = l \<and> s \<preceq> s'" "\<lambda> (l, s) (l', s'). l' = l \<and> s \<prec> s'"
  E "(l\<^sub>0, s\<^sub>0)" RE
  "\<lambda> (l, s) (l', s'). l' = l \<and> s \<prec> s'" covered
  supply [intro] = order_trans less_trans less_imp_le
  apply standard
         apply (auto simp: less_le_not_le; fail)
        apply (auto simp: less_le_not_le; fail)
       apply (auto simp: less_le_not_le; fail)
      apply clarsimp
      apply (drule mono, assumption+, (simp add: Graph_Start_Defs.reachable_def; fail)+)
      apply blast
     apply (clarsimp simp: Graph_Start_Defs.reachable_def; safe)
  subgoal for l s
    apply (drule invariant)
    using reachable unfolding covered_def RE_def by fastforce
  subgoal for l s l' s'
    apply (drule invariant)
    unfolding RE_def covered_def using E_T by force
  subgoal
    using E_T by force
  subgoal
    unfolding RE_def using E_T by force
  subgoal
    unfolding Graph_Start_Defs.reachable_def
  proof -
    have 1: "finite {(l, s). l \<in> L \<and> s \<in> M l}"
    proof -
      let ?S = "{(l, s). l \<in> L \<and> s \<in> M l}"
      have "?S \<subseteq> (\<Union>l\<in>L. ((\<lambda> s. (l, s)) ` M l))"
        by auto
      also have "finite \<dots>"
        using finite by auto
      finally show "finite ?S" .
    qed
    have 2: "finite (Collect (E (l, s)))" for l s
      by (rule finitely_branching)
    let ?S = "{a. RE\<^sup>*\<^sup>* (l\<^sub>0, s\<^sub>0) a}"
    have "?S \<subseteq> {(l\<^sub>0, s\<^sub>0)} \<union> (\<Union> ((\<lambda> a. {b. E a b}) ` {(l, s). l \<in> L \<and> s \<in> M l}))"
      using invariant by (auto simp: RE_def elim: rtranclp.cases)
    also have "finite \<dots>"
      using 1 2 by auto
    finally show "finite ?S" .
  qed
  done

context
  assumes no_subsumption_cycle: "G'.reachable x \<Longrightarrow> x \<rightarrow>\<^sub>G\<^sup>+' x \<Longrightarrow> x \<rightarrow>\<^sub>G\<^sup>+ x"
  fixes F :: "'b \<times> 'a \<Rightarrow> bool" \<comment> \<open>Final states\<close>
  assumes F_mono[intro]: "F (l, a) \<Longrightarrow> a \<preceq> b \<Longrightarrow> F (l, b)"
begin

interpretation Liveness_Compatible_Subsumption_Graph
  "\<lambda> (l, s) (l', s'). l' = l \<and> s \<preceq> s'" "\<lambda> (l, s) (l', s'). l' = l \<and> s \<prec> s'"
  E "(l\<^sub>0, s\<^sub>0)" RE F
  by standard (auto intro: no_subsumption_cycle)

lemma
  "\<nexists> x. reachable x \<and> F x \<and> x \<rightarrow>\<^sup>+ x" if "\<nexists> x. G.reachable x \<and> F x \<and> x \<rightarrow>\<^sub>G\<^sup>+ x"
  using cycle_iff that by auto

lemma no_reachable_cycleI:
  "\<nexists> x. reachable x \<and> F x \<and> x \<rightarrow>\<^sup>+ x" if "\<nexists> x. G'.reachable x \<and> F x \<and> x \<rightarrow>\<^sub>G\<^sup>+ x"
  using that cycle_iff unfolding G_G'_reachable_iff[symmetric] by auto

text \<open>
  We can certify this by accepting a set of components and checking that:
  \<^item> there are no cycles in the component graph (including subsumption edges)
  \<^item> no non-trivial component contains a final state
  \<^item> no component contains an internal subsumption edge
\<close>

end (* Final states and liveness compatibility *)

end (* Unreachability Invariant paired *)

subsection \<open>Certifying Cycle-Freeness with Graph Components\<close>
context
  fixes E1 E2 :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
  fixes S :: "'a set set"
  fixes s\<^sub>0 :: 'a and a\<^sub>0 :: "'a set"
  assumes start: "s\<^sub>0 \<in> a\<^sub>0" "a\<^sub>0 \<in> S"
  assumes closed:
    "\<forall> a \<in> S. \<forall> x \<in> a. \<forall> y. E1 x y \<longrightarrow> (\<exists> b \<in> S. y \<in> b)"
    "\<forall> a \<in> S. \<forall> x \<in> a. \<forall> y. E2 x y \<longrightarrow> (\<exists> b \<in> S. y \<in> b)"
  assumes finite: "\<forall> a \<in> S. finite a"
begin

definition "E \<equiv> \<lambda> x y. E1 x y \<or> E2 x y"

definition "C \<equiv> \<lambda> a b. \<exists> x \<in> a. \<exists> y \<in> b. E x y \<and> b \<in> S"

interpretation E1: Graph_Start_Defs E1 s\<^sub>0 .
interpretation E2: Graph_Start_Defs E2 s\<^sub>0 .
interpretation E: Graph_Start_Defs E s\<^sub>0 .
interpretation C: Graph_Start_Defs C a\<^sub>0 .

lemma E_closed:
  "\<forall> a \<in> S. \<forall> x \<in> a. \<forall> y. E x y \<longrightarrow> (\<exists> b \<in> S. y \<in> b)"
  using closed unfolding E_def by auto

interpretation E_invariant: Graph_Invariant E "\<lambda> x. \<exists> a \<in> S. x \<in> a"
  using E_closed by - (standard, auto)

interpretation E1_invariant: Graph_Invariant E1 "\<lambda> x. \<exists> a \<in> S. x \<in> a"
  using closed by - (standard, auto)

interpretation E2_invariant: Graph_Invariant E2 "\<lambda> x. \<exists> a \<in> S. x \<in> a"
  using closed by - (standard, auto)

interpretation C_invariant: Graph_Invariant C "\<lambda> a. a \<in> S \<and> a \<noteq> {}"
  unfolding C_def by standard auto

interpretation Simulation_Invariant E C "(\<in>)" "\<lambda> x. \<exists> a \<in> S. x \<in> a" "\<lambda> a. a \<in> S \<and> a \<noteq> {}"
  unfolding C_def by (standard; blast dest: E_invariant.invariant[rotated])+

interpretation Subgraph E E1
  unfolding E_def by standard auto

context
  assumes no_internal_E2:  "\<forall> a \<in> S. \<forall> x \<in> a. \<forall> y \<in> a. \<not> E2 x y"
      and no_component_cycle: "\<forall> a \<in> S. \<nexists> b. (C.reachable a \<and> C a b \<and> C.reaches b a \<and> a \<noteq> b)"
begin

lemma E_C_reaches1:
  "C.reaches1 a b" if "E.reaches1 x y" "x \<in> a" "a \<in> S" "y \<in> b" "b \<in> S"
  using that
proof (induction arbitrary: b)
  case (base y)
  then have "C a b"
    unfolding C_def by auto
  then show ?case
    by auto
next
  case (step y z c)
  then obtain b where "y \<in> b" "b \<in> S"
    by (meson E_invariant.invariant_reaches tranclp_into_rtranclp)
  from step.IH[OF \<open>x \<in> a\<close> \<open>a \<in> S\<close> this] have "C.reaches1 a b" .
  moreover from step.prems \<open>E _ _\<close> \<open>y \<in> b\<close> \<open>b \<in> S\<close> have "C b c"
    unfolding C_def by auto
  finally show ?case .
qed

lemma certify_no_E1_cycle:
  assumes "E.reachable x" "E.reaches1 x x"
    shows "E1.reaches1 x x"
proof (rule ccontr)
  assume A: "\<not> E1.reaches1 x x"
  with \<open>E.reaches1 x x\<close> obtain y z where "E.reaches x y" "E2 y z" "E.reaches z x"
    by (fastforce dest!: non_subgraph_cycle_decomp simp: E_def)
  from start \<open>E.reachable x\<close> obtain a where [intro]: "C.reachable a" "x \<in> a" "a \<in> S"
    unfolding E.reachable_def C.reachable_def by (auto dest: simulation_reaches)
  with \<open>E.reaches x y\<close> obtain b where "C.reaches a b" "y \<in> b" "b \<in> S"
    by (auto dest: simulation_reaches)
  from \<open>C.reaches a b\<close> have "C.reachable b"
    by (blast intro: C.reachable_reaches)
  from \<open>E.reaches z x\<close> have \<open>E.reaches1 z x \<or> z = x\<close> 
    by (meson rtranclpD)
  then show False
  proof
    assume "E.reaches1 z x"
    from \<open>y \<in> b\<close> \<open>b \<in> S\<close> \<open>E2 y z\<close> obtain c where "C b c" \<open>z \<in> c\<close> \<open>c \<in> S\<close>
      using A_B_step[of y z b] unfolding E_def by (auto dest: C_invariant.invariant[rotated])
    with no_internal_E2 \<open>y \<in> _\<close> \<open>E2 y z\<close> have "b \<noteq> c"
      by auto
    with \<open>E2 y z\<close> \<open>y \<in> b\<close> \<open>z \<in> c\<close> \<open>c \<in> S\<close> have "C b c"
      unfolding C_def E_def by auto
    from \<open>E.reaches1 z x\<close> \<open>z \<in> c\<close> \<open>c \<in> S\<close> \<open>x \<in> a\<close> have "C.reaches1 c a"
      by (auto intro: E_C_reaches1)
    with \<open>C.reaches a b\<close> have "C.reaches1 c b"
      by auto
    then have "C.reaches c b"
      by auto
    with \<open>C b c\<close> \<open>b \<in> S\<close> \<open>C.reachable b\<close> \<open>b \<noteq> c\<close> no_component_cycle show False
      by auto
  next
    assume [simp]: "z = x"
    with \<open>y \<in> b\<close> \<open>E2 y z\<close> \<open>a \<in> S\<close> \<open>x \<in> a\<close> have "C b a"
      unfolding C_def E_def by auto
    with no_internal_E2 \<open>y \<in> _\<close> \<open>E2 y z\<close> have "b \<noteq> a"
      by auto
    with \<open>C.reaches a b\<close> \<open>C b a\<close> \<open>b \<in> S\<close> \<open>C.reachable b\<close> no_component_cycle show False
      by auto
  qed
qed

lemma certify_no_accepting_cycle:
  assumes
    "\<forall> a \<in> S. card a > 1 \<longrightarrow> (\<forall> x \<in> a. \<not> F x)"
    "\<forall> a \<in> S. \<forall> x. a = {x} \<longrightarrow> (\<not> F x \<or> \<not> E1 x x)"
  assumes "E.reachable x" "E1.reaches1 x x"
  shows "\<not> F x"
proof (rule ccontr, simp)
  assume "F x"
  from start \<open>E.reachable x\<close> obtain a where "x \<in> a" "a \<in> S" "C.reachable a"
    unfolding E.reachable_def C.reachable_def by (auto dest: simulation_reaches)
  consider "card a = 0" | "card a = 1" | "card a > 1"
    by force
  then show False
  proof cases
    assume "card a = 0"
    with finite \<open>x \<in> a\<close> \<open>a \<in> S\<close> show False
      by auto
  next
    assume "card a > 1"
    with \<open>x \<in> a\<close> \<open>a \<in> S\<close> assms(1) \<open>F x\<close> show False
      by auto
  next
    assume "card a = 1"
    with finite \<open>x \<in> a\<close> \<open>a \<in> S\<close> have "a = {x}"
      using card_1_singletonE by blast
    with \<open>a \<in> S\<close> assms(2) \<open>F x\<close> have "\<not> E1 x x"
      by auto
    from assms(4) show False
    proof (cases rule: converse_tranclpE, assumption, goal_cases)
      case 1
      with \<open>\<not> E1 x x\<close> show ?thesis
        by auto
    next
      case (2 y)
      interpret sim: Simulation E1 E "(=)"
        by (rule Subgraph_Simulation)
      from \<open>E1.reaches1 y x\<close> have "E.reaches1 y x"
        by (auto dest: sim.simulation_reaches1)
      from \<open>E1 x y\<close> \<open>\<not> E1 x x\<close> \<open>a = _\<close> \<open>x \<in> a\<close> \<open>a \<in> S\<close> obtain b where "y \<in> b" "b \<in> S" "C a b"
        by (meson C_def E_def closed(1))
      with \<open>a = _\<close> \<open>\<not> E1 x x\<close> \<open>E1 x y\<close> have "a \<noteq> b"
        by auto
      from \<open>y \<in> b\<close> \<open>b \<in> S\<close> \<open>E.reaches1 y x\<close> \<open>x \<in> a\<close> \<open>a \<in> S\<close> have "C.reaches1 b a"
        by (auto intro: E_C_reaches1)
      with \<open>x \<in> a\<close> \<open>a \<in> S\<close> \<open>C a b\<close> \<open>C.reachable a\<close> \<open>a \<noteq> b\<close> show ?thesis
        including graph_automation_aggressive using no_component_cycle by auto
    qed
  qed
qed

end (* Cycle-freeness *)

end (* Graph Components *)

end (* Theory *)
