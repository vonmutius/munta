theory Worklist_Locales
  imports "$AFP/Refine_Imperative_HOL/Sepref"
begin

subsection \<open>Search Spaces\<close>
text \<open>
  A search space consists of a step relation, a start state,
  a final state predicate, and a subsumption preorder.
\<close>
locale Search_Space_Defs =
  fixes E :: "'a \<Rightarrow> 'a \<Rightarrow> bool" -- \<open>Step relation\<close>
    and a\<^sub>0 :: 'a                -- \<open>Start state\<close>
    and F :: "'a \<Rightarrow> bool"      -- \<open>Final states\<close>
    and subsumes :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<preceq>" 50) -- \<open>Subsumption preorder\<close>
begin
  definition reachable where
    "reachable = E\<^sup>*\<^sup>* a\<^sub>0"

  definition "F_reachable \<equiv> \<exists>a. reachable a \<and> F a"

end


locale Search_Space_Defs_Empty = Search_Space_Defs +
  fixes empty :: "'a \<Rightarrow> bool"

text \<open>The set of reachable states must be finite,
  subsumption must be a preorder, and be compatible with steps and final states.\<close>
locale Search_Space = Search_Space_Defs_Empty +
  assumes finite_reachable: "finite {a. reachable a}"

  assumes refl[intro!, simp]: "a \<preceq> a"
      and trans[trans]: "a \<preceq> b \<Longrightarrow> b \<preceq> c \<Longrightarrow> a \<preceq> c"

  assumes mono:
      "a \<preceq> b \<Longrightarrow> E a a' \<Longrightarrow> reachable a \<Longrightarrow> reachable b \<Longrightarrow> \<not> empty a \<Longrightarrow> \<exists> b'. E b b' \<and> a' \<preceq> b'"
      and empty_subsumes: "empty a \<Longrightarrow> a \<preceq> a'"
      and empty_mono: "\<not> empty a \<Longrightarrow> a \<preceq> b \<Longrightarrow> \<not> empty b"
      and empty_E: "reachable x \<Longrightarrow> empty x \<Longrightarrow> E x x' \<Longrightarrow> empty x'"
      and F_mono: "a \<preceq> a' \<Longrightarrow> F a \<Longrightarrow> F a'"

locale Search_Space' = Search_Space +
  assumes final_non_empty: "F a \<Longrightarrow> \<not> empty a"

locale Search_Space''_Defs = Search_Space_Defs_Empty +
  fixes subsumes' :: "'a \<Rightarrow> 'a \<Rightarrow> bool" (infix "\<unlhd>" 50) -- \<open>Subsumption preorder\<close>

locale Search_Space''_pre = Search_Space''_Defs +
  assumes empty_subsumes': "\<not> empty a \<Longrightarrow> a \<preceq> b \<longleftrightarrow> a \<unlhd> b"

locale Search_Space''_start = Search_Space''_pre +
  assumes start_non_empty [simp]: "\<not> empty a\<^sub>0"

locale Search_Space'' = Search_Space''_pre + Search_Space'


locale Search_Space_Key_Defs =
  Search_Space''_Defs E for E :: "'v \<Rightarrow> 'v \<Rightarrow> bool" +
  fixes key :: "'v \<Rightarrow> 'k"

locale Search_Space_Key =
  Search_Space_Key_Defs + Search_Space'' +
  assumes subsumes_key[intro, simp]: "a \<preceq> b \<Longrightarrow> key a = key b"

end