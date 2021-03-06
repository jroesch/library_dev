/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Fixed point construction on complete lattices.
-/

import .complete_lattice

universes u v w
variables {α : Type u} {β : Type v} {γ : Type w}

lemma ge_of_eq [weak_order α] {a b : α} : a = b → a ≥ b :=
λ h, h ▸ le_refl a

namespace lattice

section fixedpoint
variables [complete_lattice α] {f : α → α}

def lfp (f : α → α) : α := Inf {a | f a ≤ a}
def gfp (f : α → α) : α := Sup {a | a ≤ f a}

lemma lfp_le {a : α} (h : f a ≤ a) : lfp f ≤ a :=
Inf_le h

lemma le_lfp {a : α} (h : ∀b, f b ≤ b → a ≤ b) : a ≤ lfp f :=
le_Inf h

lemma lfp_eq (m : monotone f) : lfp f = f (lfp f) :=
have f (lfp f) ≤ lfp f,
  from le_lfp $ take b, assume h : f b ≤ b, le_trans (m (lfp_le h)) h,
le_antisymm (lfp_le (m this)) this

lemma lfp_induct {p : α → Prop} (m : monotone f)
  (step : ∀a, p a → a ≤ lfp f → p (f a)) (sup : ∀s, (∀a∈s, p a) → p (Sup s)) :
p (lfp f) :=
let s := {a | a ≤ lfp f ∧ p a} in
have p_s : p (Sup s),
  from sup s (take a ⟨_, h⟩, h),
have Sup s ≤ lfp f,
  from le_lfp $ take a, assume h : f a ≤ a, Sup_le $ take b ⟨b_le, _⟩, le_trans b_le (lfp_le h),
have Sup s = lfp f,
  from le_antisymm this $ lfp_le $ le_Sup
    ⟨le_trans (m this) $ ge_of_eq $ lfp_eq m, step _ p_s this⟩,
this ▸ p_s

lemma monotone_lfp : monotone (@lfp α _) :=
take f g, suppose f ≤ g, le_lfp $ take a, suppose g a ≤ a, lfp_le $ le_trans (‹f ≤ g› a) this

lemma le_gfp {a : α} (h : a ≤ f a) : a ≤ gfp f :=
le_Sup h

lemma gfp_le {a : α} (h : ∀b, b ≤ f b → b ≤ a) : gfp f ≤ a :=
Sup_le h

lemma gfp_eq (m : monotone f) : gfp f = f (gfp f) :=
have gfp f ≤ f (gfp f),
  from gfp_le $ take b, assume h : b ≤ f b, le_trans h (m (le_gfp h)),
le_antisymm this (le_gfp (m this))

lemma gfp_induct {p : α → Prop} (m : monotone f)
  (step : ∀a, p a → gfp f ≤ a → p (f a)) (inf : ∀s, (∀a∈s, p a) → p (Inf s)) :
p (gfp f) :=
let s := {a | gfp f ≤ a ∧ p a} in
have p_s : p (Inf s),
  from inf s (take a ⟨_, h⟩, h),
have gfp f ≤ Inf s,
  from gfp_le $ take a, assume h : a ≤ f a, le_Inf $ take b ⟨le_b, _⟩, le_trans (le_gfp h) le_b,
have Inf s = gfp f,
  from le_antisymm (le_gfp $ Inf_le
    ⟨le_trans (le_of_eq $ gfp_eq m) (m this), step _ p_s this⟩) this,
this ▸ p_s

lemma monotone_gfp : monotone (@gfp α _) :=
take f g, suppose f ≤ g, gfp_le $ take a, suppose a ≤ f a, le_gfp $ le_trans this (‹f ≤ g› a)

end fixedpoint

section fixedpoint_eqn
variables [complete_lattice α] [complete_lattice β] {f : β → α} {g : α → β}

-- Rolling rule
lemma lfp_comp (m_f : monotone f) (m_g : monotone g) : lfp (f ∘ g) = f (lfp (g ∘ f)) := 
le_antisymm
  (lfp_le $ m_f $ ge_of_eq $ lfp_eq $ monotone_comp m_f m_g)
  (le_lfp $ take a fg_le,
    le_trans (m_f $ lfp_le $ show (g ∘ f) (g a) ≤ g a, from m_g fg_le) fg_le)

lemma gfp_comp (m_f : monotone f) (m_g : monotone g) : gfp (f ∘ g) = f (gfp (g ∘ f)) := 
le_antisymm
  (gfp_le $ take a fg_le,
    le_trans fg_le $ m_f $ le_gfp $ show g a ≤ (g ∘ f) (g a), from m_g fg_le)
  (le_gfp $ m_f $ le_of_eq $ gfp_eq $ monotone_comp m_f m_g)

-- Diagonal rule
lemma lfp_lfp {h : α → α → α} (m : ∀⦃a b c d⦄, a ≤ b → c ≤ d → h a c ≤ h b d) :
  lfp (lfp ∘ h) = lfp (λx, h x x) := 
let f := lfp (lfp ∘ h) in
have f_eq : f = lfp (h f),
  from lfp_eq $ monotone_comp (take a b h x, m h (le_refl _)) monotone_lfp,
le_antisymm
  (lfp_le $ lfp_le $ ge_of_eq $ lfp_eq $ take a b h, m h h)
  (lfp_le $ ge_of_eq $
    calc f = lfp (h f)       : f_eq
       ... = h f (lfp (h f)) : lfp_eq $ take a b h, m (le_refl _) h
       ... = h f f           : congr_arg (h f) f_eq^.symm)

lemma gfp_gfp {h : α → α → α} (m : ∀⦃a b c d⦄, a ≤ b → c ≤ d → h a c ≤ h b d) :
  gfp (gfp ∘ h) = gfp (λx, h x x) := 
let f := gfp (gfp ∘ h) in
have f_eq : f = gfp (h f),
  from gfp_eq $ monotone_comp (take a b h x, m h (le_refl _)) monotone_gfp,
le_antisymm
  (le_gfp $ le_of_eq $
    calc f = gfp (h f)       : f_eq
       ... = h f (gfp (h f)) : gfp_eq $ take a b h, m (le_refl _) h
       ... = h f f           : congr_arg (h f) f_eq^.symm)
  (le_gfp $ le_gfp $ le_of_eq $ gfp_eq $ take a b h, m h h)

end fixedpoint_eqn

end lattice
