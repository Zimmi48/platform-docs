(* begin hide *)
Axiom to_fill : forall A, A.
Arguments to_fill {_}.
(* end hide *)



(** * Tutorial Equations : Basic Definitions and Reasoning with Equations

  *** Summary:
  [Equations] is a plugin for Coq that offers a powerful support
  for writing functions by dependent pattern matching, possibly using
  well-founded recursion and obligations.
  To help reason on programs, [Equations] also comes with its own set of
  tactics, and can automatically derive properties like no-confusion
  properties or subterm relations.

  In this tutorial, we introduce the basic features of [Equations], step by
  step through practical examples.

  In section 1, we explain how to define basic functions by dependent
  pattern matching using [Equations], and how [Equations] helps to reason about
  such functions.
  We then discuss [with] clauses and [where] clauses in section 2 and 3, two
  features that provide flexibility when writing functions by dependent
  pattern matching.


  *** Table of content:

  - 1. Basic definitions and reasoning
    - 1.1 Defining functions by dependent pattern matching
    - 1.2 Reasoning with [Equations]
  - 2. [With] clauses
  - 3. [Where] clauses

  *** Prerequisites:

  Needed :
  - We assume known basic knowledge of Coq, of and defining functions by recursion

  Installation:
  - Equations is available by default in the Coq Platform
  - Otherwise, it is available via opam under the name coq-equations

*)



(** * 1. Basic definitions and reasoning

  Let's start by importing the package:
*)

From Equations Require Import Equations.

(** ** 1.1 Defining functions by dependent pattern matching

    In its simplest form, [Equations] provides a practical interface to
    define functions on inductive types by pattern matching and recursion
    rather than using Fixpoint and match.
    As first examples, let's define basic functions on lists.
*)

Inductive list A : Type :=
  | nil  : list A
  | cons : A -> list A -> list A.

Arguments nil {_}.
Arguments cons {_} _ _.

(** To write a function [f : list A -> B] on lists or another a basic
      inductive type, it suffices to write :
    - Equation at the beginning of you function rather than Fixpoint
    - For each constructor [cst x1 ... xn] like [cons a l], specify how [f]
      computes on it by writing [f (cst x1 ... xn) := t] where [t] may
      contain [f] recursively.
    - Separate the different cases by semi-colon "[;]"
    - As usual finish you definition by a dot "[.]"

  For instance, we can define the function [tail], [length] and [map] by :
*)

Equations tail {A} (l : list A) : list A :=
tail nil := nil;
tail (cons a l) := l.

Equations length {A} (l : list A) : nat :=
length nil := 0;
length (cons a l) := S (length l).

Equations app {A} (l l' : list A) : list A :=
app nil l' := l';
app (cons a l) l' :=  cons a (app l l').

Infix "++" := app (right associativity, at level 60).


(** [Equations] is compatible with usual facilities provided by Coq to write
    terms :
    - It is compatible with implicit arguments that as usual do not need to
      be written provided it can be inferred, for instance, above, we wrote
      [map f nil] rather than [map f (nil A)] as [A] was declared as an
      implicit argument of [nil].
    - We can use the underscores "_" for terms that we do not use, terms
      that Coq can infer on its own, but also to describe what to do in all
      remaining cases of our pattern matching.
      As [list] only two has constructors to it is not really useful here,
      but we can still see it works by defining a constant function :
*)

Equations cst_b {A B} (b : B) (l : list A) : B :=
cst_b b (_) := b.

(** - We can use notations both in the pattern matching (on the left-hand
      side of :=) or in the bodies of the function (on the right-hand side
      of :=). This provides an easy and very visual way to define functions.
      For instance, with the usual notations for lists, we can redefine
      [length] and [map] as :
*)

Notation "[]" := nil.
Notation "[ x ]" := (cons x nil).
Notation "x :: l" := (cons x l).

Equations length' {A} (l : list A) : nat :=
length' []     := 0;
length' (a::l) := S (length' l).

Equations app' {A} (l l' : list A) : list A :=
app' []     l' := l';
app' (a::l) l' := a :: (app' l l').


(** [Equations] enables us to pattern match on several different
    variables at the same time, for instance, to define a function [nth_option]
    getting the nth-element of a list and returning [None] otherwise.
*)

Equations nth_option {A} (n : nat ) (l : list A) : option A :=
nth_option 0 nil := None ;
nth_option 0 (a::l) := Some a ;
nth_option (S n) nil := None ;
nth_option (S n) (a::l) := nth_option n l.

(** However, be careful that as for definitions using [Fixpoint], the order
    of matching matters : it produces term that are equal but with
    different computation rules.
    For instance, if we pattern match on [l] first, we get a function
    [nth_option'] that is equal to [nth_option] but computes differently
    as it can been seen when proving [eq_nth].
*)

Equations nth_option' {A} (l : list A) (n : nat) : option A :=
nth_option' [] _ := None;
nth_option' (a::l) 0 := Some a;
nth_option' (a::l) (S n) := nth_option' l n.

Goal forall {A} (a:A) n, nth_option n (nil (A := A)) = nth_option' (nil (A := A)) n.
Proof.
  (* Here [autorewrite with f] is a simplification tactic of Equation (c.f 1.1.2).
     As we can see, [nth_option'] reduces on [ [] ] to [None] but not [nth_option]. *)
  intros.
  autorewrite with nth_option.
  autorewrite with nth_option'.
Abort.

(** As exercices, you can try to define :
    - A function [map f l] that applies [f] pointwise, on [ [a, ... ,a] ] it
      returns [ [f a1, ... , f an] ]
    - A function [head_option] that returns the head of a list and [None] otherwise
    - A function [fold_right f b l] that on a list [ [a1, ..., an] ]
      returns the element [f a1 (... (f an b))]
*)

Equations map {A B} (f : A -> B) (l : list A) : list B :=
map f _ := to_fill.

Equations head_option {A} (l : list A) : option A :=
head_option _ := to_fill.

Equations fold_right {A B} (f : A -> B -> B) (b : B) (l : list A) : B :=
fold_right f b _ := to_fill.



(** ** 1.2 Reasoning with Equations  *)

(** Now that we have seen how to define basic functions, we need to
    understand how to reason about them.

    By default, the functions defined using [Equations] are opaque and can not
    be unfolded with [unfold] nor simplified with [simpl] or [cbn] as one
    would do with a [Fixpoint] definition.
    This is on purpose to prevent uncontrolled unfolding which can easily
    happen, particularly when doing well-founded recursion or reasoning
    about proof carrying functions.
    Yet, note that it does not prevent us to use reflexivity when both sides
    of an equation are definitionally equal.

    For instance, consider [nil_app] the usual computation rule for [app].
    It can not be unfolded, nor simplified by [cbn] but can be proven by
    [reflexivity].
*)

Lemma nil_app {A} (l : list A) : [] ++ l = l.
Proof.
  (* [unfold] fails, and [cbn] has no effect *)
  Fail unfold "++". Fail progress cbn.
  (* But [reflexivity] works *)
  reflexivity.
Qed.

(** If one wishes to recover unfolding, it is possible on a case by case
    basis using the option [Global Transparent f] as shown below.
    It is also possible to set this option globally with [Set Equations
    Transparent], but it is not recommended to casual users.
    To recover simplification by [simpl] and [cbn], one needs to additionally
    use the command [Arguments name_function /].
*)

Equations f4 (n : nat) : nat :=
f4 (_) := 4.

Global Transparent f4.

Goal f4 3 = 4.
Proof.
  (* [f4] can now be unfolded *)
  unfold f4. Restart.
  (* Yet, it still can not be simplify by [cbn] *)
  Fail progress cbn.
  (* [Arguments] enables to recover simplification *)
  Arguments f4 /. cbn.
Abort.

(** Rather than using [cbn] or [simpl], for each function [f], [Equations]
    internally declares an equality for each case of the pattern matching
    defining [f], in a database named [f].
    For instance, for [app], it declares [app [] l' = l'] and
    [app (a::l) l' = a :: (app l l')].
    It is then possible to simply simplify by the equations associated
    to function [f1 ... fn] using the tactic [autorewrite with f1 ... fn].
    This provide a better control of unfolding when doing in proofs as
    compared to cbn the user can choose which functions [f1 ... fn],
    they wants to simplify.

    As an example, let's prove [app_nil l : l ++ [] = l].
    As [app] is defined by pattern match on [l], we prove the result by
    induction on [l],  and uses [autorewrite with app] to simplify the goals.
    We can similarly prove that [app] is associative.
*)

Lemma app_nil {A} (l : list A) : l ++ [] = l.
Proof.
  intros; induction l. all: autorewrite with app.
  - reflexivity.
  - rewrite IHl. reflexivity.
Abort.

(** In the example above of [app_nil], we mimicked the pattern used in the
    definition of [app] by [induction l].
    While it works on simple examples, it quickly gets more complicated.
    For instance, consider the barely more elaborate example proving
    that both definition of [nth_option] are equal.
    We have to be careful to first revert [n] in order to generalise the
    induction hypothesis and get something strong enough when inducting on [l],
    and we then need to detruct n.
*)

Lemma nth_eq {A} (l : list A) (n : nat) : nth_option n l = nth_option' l n.
Proof.
  revert n; induction l; intro n; destruct n.
  all : autorewrite with nth_option nth_option'.
  - reflexivity.
  - reflexivity.
  - reflexivity.
  - apply IHl.
Abort.

(** This process quickly gets tedious and complicated to do by hand on real life examples,
    especially when using complicated inductive types, or more advanced
    notions of matching like [with] and [where] clauses (c.f 1.2).
    Consequently, [Equations] comes with a tactic [funelim] that automatically
    does an induction following the pattern matching used to define a
    function, there is no need to do it by hand.
    Moreover, it does so directly with the good induction hypothesis, there
    is no need to generalise the induction hypothesis as done by
    reverting [n] in the proof of [nth_eq] above.
    To use it, it suffices to write [funelim (name_function a1 ... an)]
    where [a1 ... an] are the arguments you want to do your induction on.

    As an example, let's prove [app_nil], [app_assoc], and [nth_eq] for
    which we can already see the advantages over trying to reproduce the
    pattern matching by hand :
*)

Lemma app_nil {A} (l : list A) : l ++ [] = l.
Proof.
  funelim (app l []). all: autorewrite with app.
  - reflexivity.
  - rewrite H. reflexivity.
Qed.

Lemma app_assoc {A} (l1 l2 l3 : list A) : (l1 ++ l2) ++ l3 = l1 ++ (l2 ++ l3).
Proof.
  funelim (app l1 l2). all : autorewrite with app.
  - reflexivity.
  - rewrite H. reflexivity.
Qed.

Lemma nth_eq {A} (l : list A) (n : nat) : nth_option n l = nth_option' l n.
Proof.
  funelim (nth_option n l).
  all: autorewrite with nth_option nth_option'.
  - reflexivity.
  - reflexivity.
  - reflexivity.
  - apply H.
Abort.

(** By default, the tactic [autorewrite with f] only simplify a term by the
    equations defining [f], like [[] ++ l = l] for [app].
    Yet, in practice, it often happens that there are more equations
    that we have proven that we would like to automatically simplify by
    when proving further properties.
    For instance, when reasoning on [app], we may want to further always simplify
    by [app_nil : l + [] = l] or [app_assoc : (l1 ++ l2) ++ l3 = l1 ++ (l2 ++ l3)].
    It is possible to extend [autorewrite] to make it automatic by adding
    lemma to the database associated to [f].
    This can be done by the syntax :

      [ #[local] Hint Rewrite @name_lemma : name_function. ]

    This provides us with a very powerful personnalisable rewrite mechanism.
    However, please note that this mechanism is powerful enough for it
    to become non terminating if one adds the right lemma.

    To see how it can be useful, let's define a tail-recursive version of
    list reversal and prove it equal the usual one :
*)

Equations rev {A} (l : list A) : list A :=
rev [] := [];
rev (a::l) := rev l ++ [a].

Equations rev_acc {A} (l : list A) (acc : list A) : list A :=
rev_acc nil acc := acc;
rev_acc (cons a v) acc := rev_acc v (a :: acc).

Lemma rev_rev_acc {A} (l l' : list A) : rev_acc l l' = rev l ++ l'.
Proof.
  funelim (rev l). all: autorewrite with rev rev_acc app.
  - reflexivity.
  (* We have to rewrite by [app_assoc] by hand *)
  - rewrite app_assoc. apply H.
Abort.

(* Adding [app_nil] and [app_assoc] the database associated to [app] *)
#[local] Hint Rewrite @app_nil @app_assoc : app.

(* [autorewrite with app] can now use [app_assoc] *)
Goal forall {A} (l1 l2 l3 l4 : list A),
     ((l1 ++ l2) ++ l3) ++ l4 = l1 ++ (l2 ++ (l3 ++ l4)).
Proof.
  intros. autorewrite with app. reflexivity.
Qed.

Lemma rev_eq {A} (l l' : list A) : rev_acc l l' = rev l ++ l'.
Proof.
  funelim (rev l). all: autorewrite with rev rev_acc app.
  - reflexivity.
  (* There is no more need to call it by hand in proofs *)
  - apply H.
Abort.

(** In practice, it also often happens that after simplification we get a
    lot of uninteresting cases when proving properties by induction,
    properties that we would like to deal with automatically in a controlled way.
    To help us, [Equations] provides us with a tactic [simp f1 ... fn]
    that first simplify the goal by [autorewrite with f1 ... fn] then
    tries to solve the goal by a proof search by a particular instance of
    [try typeclasses eauto].
    It does so using the equations associated to [f1 ... fn], and a few more
    lemmas specific to [Equations] meant to ease the proof search.
    Though, please note that this proof search does not run [reflexivity].

    Linking [simpl] with [funelim] like [funelim sth ; simp f1 ... fn] then
    enables us to simplify all the goals and at the same to automatically
    prove uninterresting ones.
    As examples, let's reprove [nth_eq] and [rev_rev_acc] :
*)

Definition nth_eq {A} (l : list A) (n : nat) : nth_option n l = nth_option' l n.
Proof.
  funelim (nth_option n l). all: simp nth_option nth_option'.
  all : reflexivity.
Abort.

Lemma rev_eq {A} (l l' : list A) : rev_acc l l' = rev l ++ l'.
Proof.
  funelim (rev l). all: simp rev rev_acc app.
  reflexivity.
Qed.




(** As exercices, you can try to prove the following properties  *)
Lemma app_length {A} (l l' : list A) : length (l ++ l') = length l + length l'.
Proof.
Admitted.

(* You will need to use the lemma [le_S_n] *)
Lemma nth_overflow {A} (n : nat) (l : list A) : length l <= n -> nth_option n l = None.
Proof.
Admitted.

(* You will need to use the lemma [Arith_prebase.lt_S_n] *)
Lemma app_nth1 {A} (n : nat) (l l' : list A) :
      n < length l -> nth_option n (l++l') = nth_option n l.
Proof.
Admitted.

(* You will need the lemma [PeanoNat.Nat.sub_succ] and [le_S_n].
  HINT : [funelim] must be applied to the parameters you are doing the induction on.
         Here, it is [n] and [l], and not [(n - length l)] and [l']. *)
Lemma app_nth2 {A} (n : nat) (l l' : list A) :
      length l <= n -> nth_option n (l++l') = nth_option (n-length l) l'.
Proof.
Admitted.

Lemma distr_rev {A} (l l' : list A) : rev (l ++ l') = rev l' ++ rev l.
Proof.
Admitted.





(** ** 1.2 With clauses

    The structure of real programs is richer than a simple case tree on the
    original arguments in general.
    In the course of a computation, we might want to compute or scrutinize
    intermediate results (e.g. coming from function calls) to produce an answer.
    In terms of dependent pattern matching, this literally means adding a new
    pattern to the left of our equations made available for further refinement.
    This concept is know as [with] clauses in the Agda community and was first
    introduced in the Epigram language.

    [With] clause are available in [Equations] with the following syntax
    where [b] is the term we wish to inspect, and [p1 ... pk] the patterns we
    match [b] to :

    [[
      f (cxt x1 ... xn) with b => {
      (cxt x1 ... xn) p1 := ... ;
      ...
      (cxt x1 ... xn) pk := ...
    }
    ]]

    As a first example, we can a define a function filtering a list by a
    predicate [p].
    In the case [cons a l], the [with] clause enables us to compute
    the intermediate value [p a] and to check whether it is [true] or [false],
    and hence if [a] verify the predicate [p] and should be kept or not :
*)

Equations filter {A} (l : list A) (p : A -> bool) : list A :=
filter nil p := nil ;
filter (cons a l) p with p a => {
  filter (cons a l) p true := a :: filter l p ;
  filter (cons a l) p false := filter l p }.


(** This syntax is a bit heavy, to avoid repeating the same patterns in
    multiple clauses and focus on the patterns we can use a more compact
    syntax.
    Similarly to the [Fixpoint] syntax, by starting each clause with "[|]" and
    separating the list of patterns by "[,]", we do not need to repeat the
    name of the functions, put parenthesis or finish a line by "[;]".
    Moreover, in a [with] clause, we only need to specify the patterns
    introduced by the [with] clause.

    This enables to rewrite the [with] clause of the function filter
    much more concisely :
*)

Equations filter' {A} (l : list A) (p : A -> bool) : list A :=
filter' [] p => [];
filter' (a :: l) p with p a => {
  | true  => a :: filter' l p
  | false => filter' l p }.

(** If you wish, it is also possible to use this syntax for the main body
    of you functions as below:
*)

Equations filter'' {A} (l : list A) (p : A -> bool) : list A :=
  | [], p => []
  | a :: l, p with p a => {
    | true  => a :: filter'' l p
    | false => filter'' l p }.

(** To show that [filter] is well-behaved we can define a predicate [In] and
    check that if an element is in the list and verifies the predicate,
    then it is in the filtered list.
*)

Equations In {A} (x : A) (l : list A) : Prop :=
In x [] => False ;
In x (a::l) => (x = a) \/ In x l.

(** For function defined using [with] clauses, [funelim] does the usual
    disjunction of cases for us, and additionally destruct the pattern
    associated to the |with] clause and remembers it.
    In the case of [filter], it means additionally destructing [p a] and
    remembering  whether [p a = true] or [p a = false].

    For regular patterns, simplifying [filter] behaves as usual.
    For the [with] clause, simplifying [filter] makes a subclause
    corresponding to the current case appear.
    For [filter], it makes appear [filter_clause_1] in the case [p a = true],
    and [filter_clause_2] in the case [p a = false].
    This is due to [Equations] internal mechanics.
    To simplify the goal further, it suffices to rewrite [p a] by its value
    in the branch, and to simplify [filter] again.
*)

Lemma filter_In {A} (x : A) (l : list A) (p : A -> bool)
      : In x (filter l p) <-> In x l /\ p x = true.
Proof.
  funelim (filter l p); simp filter In.
  - intuition congruence.
  - rewrite Heq; simp filter In. rewrite H. intuition congruence.
  - rewrite Heq; simp filter In. rewrite H. intuition congruence.
Qed.

(** [With] clauses can also be useful to inspect a recursive call.
    For instance, with clause enables us to define a particularly concise
    definition of the [unzip] function:
*)

Equations unzip {A B} (l : list (A * B)) : list A * list B :=
unzip [] := ([],[]);
unzip ((a,b)::l) with unzip l => {
  | (la,lb) => (a::la, b::lb)
}.

(** They can also be useful to discard impossible branches.
    For instance, rather than returning an option type, we can define a
    [head] function by requiring that its input is different than the
    empty list.
    In the [nil] case, we can then destruct [pf eq_refl : False] which
    as no constructors to define our function.
*)

Equations head {A} (l : list A) (pf : l <> nil) : A :=
head [] pf with (pf eq_refl) := { };
head (a::l) _ := a.

(** As exercices, you can try to :
    - Define a function [find_dictionary] that given a key and an
      equality test, return the first element associated to the key and
      [None] otherwise
    - Prove that both head functions are equal up to [Some]
    - Prove that a filtered list is small than the original one
*)

Equations find_dictionary {A B} (eq : A -> A -> bool) (key : A)
          (l : list (A * B)) : option B :=
find_dictionary eq key [] := to_fill;
find_dictionary eq key _ with to_fill => {
  | _ := to_fill
}.

Definition head_head {A} (l : list A) (pf : l <> nil)
           : Some (head l pf) = head_option l.
Proof.
Admitted.

(* You may need the lemma le_n_S and PeanoNat.Nat.le_le_succ_r *)
Definition filter_length {A} (l : list A) (p : A -> bool)
           : length (filter l p) <= length l.
Proof.
Admitted.




(** ** 1.3 Where Clauses

    As discussed, it often happens that we need to compute intermediate terms
    which is the purpose of the [with] clause.
    Similarly, it often happens that we need to define intermediate
    functions, for instance to make the code clearer or because a function
    needs to be generalised.

    This is the purpose of the [where] clause, that enables to define auxiliary
    function defined in the context of the main one.
    To define a function using a [where] clause, it suffices to start
    a new block after the main body starting with [where] and using
    [Equations] usual syntax.
    Though be careful that as it is defined in the context of the main
    body, it is not possible to reuse the same names.

    The most standard example is a tail-recursive implementation of list
    reversal using an accumulator.
    As an example, we reimplement it with a [where] clause rather than with an
    external definition.
*)

Equations rev_acc' {A} (l : list A) : list A :=
rev_acc' l := rev_acc_aux l []

where rev_acc_aux : (list A -> list A -> list A) :=
rev_acc_aux [] acc := acc;
rev_acc_aux (a::tl) acc := rev_acc_aux tl (a::acc).

(** Reasoning on functions defined using [where] clauses is a bit more tricky as we
    need a predicate for the first function, and for the auxiliary function.
    The first one is usually call the wrapper and the other the worker.
    While the first one is obvious as it is the property we are trying to prove,
    Coq can not invent the second one on its own.
    Consequently, we can not simply apply [funelim]. We need to apply ourself
    the recurrence principle [rev_acc_elim] automatically generated by [Equations]
    for [rev_acc] that is behind [funelim].
*)

Lemma rev_acc_rev {A} (l : list A) : rev_acc' l = rev l.
Proof.
  unshelve eapply rev_acc'_elim.
  exact (fun A _ l acc aux_res => aux_res = rev l ++ acc). all: cbn; intros.
  (* Functional elimination provides us with the worker property initialised
    as in the definition of the main function *)
  - rewrite app_nil in H. assumption.
  (* For the worker proofs themselves, we use standard reasoning. *)
  - reflexivity.
  - simp rev. rewrite H. rewrite app_assoc. reflexivity.
Abort.

(** This proof can actually be mostly automatised thanks to [Equations].
    - We can automatically deal with [app_nil] and [app_assoc] by adding
      them to simplification done by [autorewrite] as done in 1.1.2
    - We can combine that with a proof search using [simp]
    This enables to rewrite the proof to :
*)

Lemma rev_acc_rev {A} (l : list A) : rev_acc' l = rev l.
Proof.
  unshelve eapply rev_acc'_elim.
  exact (fun A _ l acc aux_res => aux_res = rev l ++ acc).
  all: cbn; intros; simp rev app in *.
  reflexivity.
Qed.
