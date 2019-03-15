open Model_Checker;

(*** Printing utilites ***)
fun println s = print (s ^ "\n")

fun list_to_string f = (fn x => "[" ^ x ^ "]") o String.concatWith ", " o map f;

fun print_result NONE = println("Invalid input\n")
    | print_result (SOME true) = println("Property is satisfied\n")
    | print_result (SOME false) = println("Property is not satisfied\n")

fun print_timings () =
  let
    val tab = Timing.get_timings ();
    fun print_time (s, t) = println(s ^ ": " ^ Time.toString t);
  in map print_time tab; () end;

(*** Wrapping up the checker ***)
fun run_and_print implementation num_threads check_deadlock s =
  let
    val debug_level: Int32.int Unsynchronized.ref = ref 0
    val _ = debug_level := 2
    val t = Time.now ()
    (* val r = parse_convert_run_print check_deadlock s () *)
    val r = parse_convert_run_check implementation num_threads check_deadlock s ()
    val t = Time.- (Time.now (), t)
    val _ = println("")
    val _ = println("Internal time for precondition check + actual checking: " ^ Time.toString t)
    val _ = println("")
    val _ = print_timings ()
  in ()
  (*
    case r of
      Error es => let
        val _ = println "Failure:"
        val _ = map println es
      in () end
    | Result r => let
      val _ = if !debug_level >= 1 then let
          val _ = println("# explored states: " ^ Int.toString(Tracing.get_count ()))
          val _ = println("")
        in () end else ()
      in println r end
  *)
  end;

fun read_lines stream =
  let
    val input = TextIO.inputLine stream
      handle Size => (println "Input line too long!"; raise Size)
  in
    case input of
      NONE => ""
    | SOME input => input ^ read_lines stream
  end;

fun check_and_verify_from_stream implementation num_threads model check_deadlock =
  let
    val stream = TextIO.openIn model
    val input = read_lines stream
    val _ = TextIO.closeIn stream
  in
    if input = ""
    then println "Failed to read line from input!"
      (* We append a space to terminate the input for the parser *)
    else input ^ " " |> run_and_print implementation num_threads check_deadlock
  end;

fun find_with_arg P [] = NONE
  | find_with_arg P [_] = NONE
  | find_with_arg P (x :: y :: xs) = if P x then SOME y else find_with_arg P (y :: xs)

fun read_file f =
  let
    val file = TextIO.openIn f
    val s = read_lines file
    val _ = TextIO.closeIn file
  in s end;

structure Bound : BOUND = struct

type bound = int dBMEntry;
type isabelle_int = int;
val isabelle_int = Int_of_integer o IntInf.fromInt;
val magic_number = 42;
val lte = Le o Int_of_integer o IntInf.fromInt;
val lt  = Lt o Int_of_integer o IntInf.fromInt;
val inf = INF;

end

structure Deserialize = Deserializer64Bit(Bound);

fun read_certificate_from_file f =
  let
    val file = BinIO.openIn f
    val r = Deserialize.deserialize file
    val _ = BinIO.closeIn file
  in r end;

fun read_and_check check_deadlock (model, certificate, renaming, implementation, num_threads) =
  let
      val model = read_file model
      val renaming = read_file renaming
      val _ = Timing.start_timer ()
      val certificate = read_certificate_from_file certificate
      val _ = Timing.save_time "Time to deserialize certificate"
    in
      case certificate of
        NONE => println "Failed to read certificate! (malformed)"
      | SOME certificate => (
          parse_convert_check implementation num_threads check_deadlock model renaming certificate ();
          print_timings ()
          )
    end

fun main () =
  let
    val args = CommandLine.arguments()
    val check_deadlock = List.find (fn x => x = "-deadlock" orelse x = "-dc") args <> NONE
    val cpu_time = List.find (fn x => x = "-cpu-time" orelse x = "-cpu") args <> NONE
    val model = find_with_arg (fn x => x = "-model" orelse x = "-m") args
    val certificate = find_with_arg (fn x => x = "-certificate" orelse x = "-c") args
    val renaming = find_with_arg (fn x => x = "-renaming" orelse x = "-r") args
    val num_threads = find_with_arg (fn x => x = "-num-threads" orelse x = "-n") args
    val implementation = find_with_arg (fn x => x = "-implementation" orelse x = "-i") args
    fun convert f NONE = NONE
      | convert f (SOME x) = SOME (f x)
        handle Fail msg => (println ("Argument error: " ^ msg); OS.Process.exit OS.Process.failure)
    fun int_of_string err_msg s = case Int.fromString s of
        NONE => raise Fail (err_msg ^ " should be an integer")
      | SOME x => x
    fun int_to_impl n =
      if n < 1 orelse n > 4 then
        raise Fail "Implementation needs to be in the range 1 to 4"
      else if n = 1 then Impl1
      else if n = 2 then Impl2
      else Impl3
    fun the_default x NONE = x
      | the_default _ (SOME x) = x
    val implementation = implementation
      |> convert (fn x => x |> int_of_string "Implementation")
      |> the_default 1
    val num_threads = num_threads
      |> convert (int_of_string "Number of threads")
      |> the_default 1
    val _ = println "** Configuration options **"
    val _ = "* Deadlock: " ^ (if check_deadlock then "True" else "False") |> println
    val _ = "* Implementation: " ^ Int.toString implementation |> println
    val _ = "* Num Threads: " ^ Int.toString num_threads |> println
    val _ = "* Measuring CPU time: " ^ (if cpu_time then "True" else "False") |> println
    (* val _ = if implementation = 4 then Par_List.set_num_threads num_threads else () *)
    (* val num_threads = if implementation = 4 then 100000 else num_threads *)
    val _ = Par_List.set_num_threads num_threads
    val num_threads = 10000
    val num_threads = num_threads |> IntInf.fromInt |> nat_of_integer
    val implementation = int_to_impl implementation
    val args = [model, certificate, renaming]
    val _ = if cpu_time then Timing.set_cpu true else ()
  in
    if certificate = NONE andalso renaming = NONE andalso model <> NONE then
      (
        println "Falling back to munta!";
        check_and_verify_from_stream implementation num_threads (the model) check_deadlock
      )
    else if exists (fn x => x = NONE) args then
      println "Missing command line arguments!"
    else
      let
        val [model, certificate, renaming] = map the args
      in
        read_and_check check_deadlock (model, certificate, renaming, implementation, num_threads)
      end
  end