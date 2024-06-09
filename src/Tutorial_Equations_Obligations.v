(** * Equations and Obligations

  *** Summary

  [Equations] is a plugin for %\cite{Coq}% that offers a powerful support
  for writing functions by dependent pattern matching.
  In this tutorial, we discuss how it interface with [Program] to help write
  programs using obligations.

  In section 1, we recall the concept of obligation and how they interface with [Equations].
  In Section 2, we discuss [Equations]' obligation solving tactic.


  *** Table of content

  - 1. Equations and Obligations
    - 1.1 Obligations
    - 1.2 Solving obligations
  - 2. Equations' solving tactic
    - 2.1 Personalizing the tactic proving obligations
    - 2.2 What to do if goals are oversimplified


  *** Prerequisites

  Needed:
  - We assume basic knowledge of Coq, and of defining functions by recursion
  - We assume basic knowledge of the Equations plugin, e.g, as presented
    in the tutorial Equations: Basics

  Not needed:

  Installation:
  - Equations is available by default in the Coq Platform
  - Otherwise, it is available via opam under the name coq-equations

*)


From Coq Require Import List.
Import ListNotations.

From Equations Require Import Equations.

Axiom to_fill : forall A, A.
Arguments to_fill {_}.


(** ** 1. Equations and Obligations

    *** 1.1 Obligations

    In some cases, to define functions we may have to prove properties.
    There can be many reasons for that. Among others, the data structure under
    consideration may can include invariants that we must prove to be preserved
    when defining functions.

    For instance, vectors of size [n] can be defined as lists of length [n],
    that is, as a list [l] with a proof that [length l = n].
*)

Definition vec A n := { l : list A | length l = n }.

(** To define a function [vec A n -> vec A m], one has to explain how the
    function acts on lists, and to prove that the resulting list is of size
    [m] providing the original one is of size [n].

    For instance, to define a concatenation function on vectors
    [vapp : vec A n -> vec A m -> vec A (n + m)], as done below, one has to:
    - specify that the concatenation of [l] and [l'] is [app l l'] and,
    - provide a proof term that [length (ln ++ lm) = n + m], which is done
      below by the term [eq_trans (app_length ln lm) (f_equal2 Nat.add Hn Hm)].
*)

Equations vapp {A n m} (v1 : vec A n) (v2 : vec A m) : vec A (n + m) :=
vapp (exist _ ln Hn) (exist _ lm Hm) :=
      (exist _ (app ln lm)
               (eq_trans (app_length ln lm) (f_equal2 Nat.add Hn Hm))).

(** Yet, in most cases, when defining a function, we do not want to write down
    the proofs directly as terms, as we did above.
    There are many reasons for that:
    - in practice, proof terms can be arbitrarily large and complex making it
      tedious if not impossible to write them down directly as terms
    - even if we could, this can easily make the function completely illegible
    - in case of changes, it is not possible to replay a term proof as we can
      replay a tactic script in order to adapt it, making functions harder
      to adapt

    Therefore, we would much rather like to build our terms using the proof mode.
    This is exactly what [Program] and obligations enables us to do.
    At every point in a definition, it enables us:
    - 1. write down a wildcard [_] instead of a term
    - 2. it will then create an obligation, intuitively a goal left to solve
      to complete the definition
    - 3. it will try to simplify the obligations and solve them using a tactic,
      in our case, using a tactic specific to [Equations]
    - 4. if they are any obligations left to solve, we can prove them using
      the proof mode and tactics using [Next Obligation] or [Equations?] that
      we discuss in section 1.2


    For instance, we can define a function [vapp n m : vec A n -> vec A m -> vec A (n+m)]
    using a wildcard [_] where a proof of [length (app ln lm) = n + m]
    is expected to prove it using tactics:
*)

Equations vapp' {A n m} (v1 : vec A n) (v2 : vec A m) : vec A (n + m) :=
vapp' (exist _ ln Hn) (exist _ lm Hm) := exist _ (app ln lm) _.
Next Obligation.
  apply app_length.
Qed.

(** As you can see, this very pratical however, you should be aware of
    three basic pitfalls that:

    1. As you may have noticed the goal to prove was not [length (app ln lm) = n + m]
    as expected, but [length (app ln lm) = length ln + length lm].
    It is because [Equations] custom solving tactic has already pre-simplified
    the goal for us. In can be an issue in some cases, and we discuss it in
    section 2.1.

    2. Technically, you can use a wildcard [_] for any term, even for one
    relevant to the definition and computation like [app ln lm] .
    Yet, it generally it is a bad idea as automation could then infer
    something random that matches the type expected.

    3. Be aware that a definition is not defined until the all its associated
    obligations have been solved. Trying to refer to it before that, we
    consequently return that the defintion was not found.
    For instance, consider the unfinished definition of [vmap] with a wildcar [_]
*)

Equations vmap {A B n} (f : A -> B) (v : vec A n) : vec B n :=
vmap f (exist _ ln Hn) := exist _ (map f ln) _ .

Fail Definition vmap_comp {A B C n} (g : B -> C) (f : A -> B) (v : vec A n)
    : vmap g (vmap f n v) = vmap (fun x => g (f x)) v.


(** *** 1.2 Solving obligations

    There are two different methods to solve the remaining obligations.

    You can solve the obligations one by one using the command [Next Obligations].
    Doing so for [vmap] display the goal [length (map f ln) = length ln],
    which we can then solve using tactics..
*)

Next Obligation.
  apply map_length.
Qed.

(** Using [Next Obligation] has the advantage that once an obligation has been
    solved, [Program] retries automatically to prove the remaining obligations.
    It can be practical when proofs are simple but requires for a evariable
    to be solved first to be able to proceed.

    Note, that it can be useful to add [Fail Next Obligation] once all
    obligations have been solved.
    This way, if a change somewhere now leaves an obligation unsolved, we can
    easily track down the issue to the culprit definition.

    Alternatively, it is possible to use the keyword [Equations?] to automatically
    unshelve all obligations, that is enter the proof mode and create a goal
    for each of the obligations remaining.

    For an example, we can redefine [vmap] using it:
*)

Equations? vmap' {A B n} (f : A -> B) (v : vec A n) : vec B n :=
vmap' f (exist _ ln Hn) := exist _ (map f ln) _ .
Proof.
  apply map_length.
Defined.

(** Though, note that [Equations?] triggers a warning when used on a definition
    that leaves no obligations unsolved.
    It is because for technical reasons, [Equations?] cannot check if there
    is at least on obligation left to solve before opening the proof mode.
    Hence, when there is no obligation proof mode is open for nothing, and
    has to be closed by hand using [Qed] or [Defined] as it can be seen below.
    As it is easy to forget, a warning is raised.
*)

Equations? vnil {A} : vec A 0 :=
vnil := exist _ nil eq_refl.
Defined.


(** ** 2. Equations' solving tactic

    As mentioned, [Equations] automatically tried to solve obligations.
    It does so using a custom strategy basically simplifying the goals and
    running a solver.
    It can be viewed with the following command:
*)

Show Obligation Tactic.

(** 2.1 Personalizing the tactic proving obligations

    When working, it is common to be dealing with a particular class of
    functions that shares a common theory, e.g, they involve basic arithmetic.
    This theory cannot not be guessed from the basic automation tactic,
    so may be personalizing a tactic to handle this particular theory.

    This can be done using the command [ #[local] Obligation Tactic := tac ]
    that changes locally the tactic solving obligation to [tac].

    For an example, consider a [gcd] function defined by well-founded recursion.
    There are two obligations left to prove corresponding to proofs that the recursive
    call are indeed performed on smaller instance.
    Each of them corresponds to basic reasoning about arithmetics, and can
    be solved with the solver [lia].
*)

Require Import Arith Lia.

Equations? gcd (x y : nat) : nat by wf (x + y) lt :=
gcd 0 x := x ;
gcd x 0 := x ;
gcd x y with gt_eq_gt_dec x y := {
  | inleft (left _) := gcd x (y - x) ;
  | inleft (right refl) := x ;
  | inright _ := gcd (x - y) y }.
Proof.
  lia. lia.
Abort.

(** Therefore, we would like to locally change the tactic solving the
    obligations to take into account arithmetic, and try [lia].
    We do so by simply trying it after the current solving tactic,
    i.e. the one displayed by [Show Obligation Tactic].
    As we can see by running again [Show Obligation Tactic], it has indeed been
    added, and [gcd] is now accepted directly.
*)

#[local] Obligation Tactic :=
          simpl in *;
          Tactics.program_simplify;
          CoreTactics.equations_simpl;
          try Tactics.program_solve_wf;
          try lia.

Show Obligation Tactic.

Equations gcd (x y : nat) : nat by wf (x + y) lt :=
gcd 0 x := x ;
gcd x 0 := x ;
gcd x y with gt_eq_gt_dec x y := {
  | inleft (left _)     := gcd x (y - x) ;
  | inleft (right refl) := x ;
  | inright _           := gcd (x - y) y
  }.

(** 2.2 What to do if goals are oversimplified

    In some cases, it can happen that [Equations]' solving tactic is too abrut
    and oversimply goals, or mis-specialised  and ended up getting us stuck.
    In this case, it can be useful to set the solving tactic to the identify.

    For an example, let's define a function
    [vzip :  vec A n -> vec B n -> vec (A * B) n] without using [list_prod].
    In all cases where a proof is expected we create an obligation, and uses
    the proof mode to handle the reasoning on arithmetics.
    We also use obligations to disregard the case [nil (b::lb)] and [(a::la) nil].

    As it can be seen below, [Equations] can automatically with the first three
    goal, and first ask us which integer is used [n] the first.
    TODO ??
*)

  Equations? vzip {A B n} (va : vec A n) (vb : vec B n) : vec (A * B) n :=
  vzip (exist _ [] ea)      (exist _ [] eb)      => exist _ [] _;
  vzip (exist _ [] ea)      (exist _ (b::lb) eb) => _;
  vzip (exist _ (a::la) ea) (exist _ [] eb)      => _;
  vzip (exist _ (a::la) ea) (exist _ (b::lb) eb)
    with vzip (exist _ la _) (exist _ lb _ ) := {
    | exist _ l _ => exist _ ((a,b)::l) _
    }.
  Proof.
    - exact (length lb).
    -
  Abort.


(** Consequently, it can be easier to change the tactic locally to TODO  *)
#[local] Obligation Tactic := idtac.

Equations? vzip {A B n} (va : vec A n) (vb : vec B n) : vec (A * B) n :=
vzip (exist _ [] ea)      (exist _ [] eb)      => exist _ [] _;
vzip (exist _ [] ea)      (exist _ (b::lb) eb) => _;
vzip (exist _ (a::la) ea) (exist _ [] eb)      => _;
vzip (exist _ (a::la) ea) (exist _ (b::lb) eb)
  with vzip (exist _ la _) (exist _ lb _ ) := {
  | exist _ l _ => exist _ ((a,b)::l) _
  }.
Proof.
  - exact ea.
  - cbn in *. rewrite <- ea in eb; inversion eb.
  - cbn in *. rewrite <- ea in eb; inversion eb.
  - destruct n. 1: inversion ea. exact n.
  - destruct n; inversion ea. reflexivity.
  - destruct n; inversion eb. reflexivity.
  - destruct n; inversion ea. cbn. rewrite e, H0. reflexivity.
Defined.