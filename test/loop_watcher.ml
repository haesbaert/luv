open Test_helpers

let for_watcher_kind init (start : callback:(_ -> unit) -> _ -> _) stop =
  let with_watcher f =
    let watcher =
      init ()
      |> check_success_result "init"
    in

    let result = f watcher in

    Luv.Handle.close watcher;
    run ();

    result
  in

  [
    "init, close", `Quick, begin fun () ->
      with_watcher ignore
    end;

    "loop", `Quick, begin fun () ->
      with_watcher begin fun watcher ->
        Luv.Handle.get_loop watcher
        |> check_pointer "loop" default_loop
      end
    end;

    "start, stop", `Quick, begin fun () ->
      with_watcher begin fun watcher ->
        let calls = ref 0 in

        start watcher ~callback:begin fun watcher' ->
          if not (watcher' == watcher) then
            Alcotest.fail "same prepare handle";

          calls := !calls + 1;
          if !calls = 2 then
            stop watcher
            |> check_success "stop"
        end
        |> check_success "start";

        while Luv.Loop.run default_loop Luv.Loop.Run_mode.nowait do
          ()
        done;

        Alcotest.(check int) "calls" 2 !calls
      end
    end;

    "double start", `Quick, begin fun () ->
      with_watcher begin fun watcher ->
        let first_called = ref false in
        let second_called = ref false in

        start watcher ~callback:(fun _ ->
          first_called := true)
        |> check_success "first start";
        start watcher ~callback:(fun _ ->
          second_called := true)
        |> check_success "second start";

        Luv.Loop.run default_loop Luv.Loop.Run_mode.nowait |> ignore;

        Alcotest.(check bool) "first called" true !first_called;
        Alcotest.(check bool) "second called" false !second_called
      end
    end;
  ]

let tests = [
  "prepare", Luv.Prepare.(for_watcher_kind init start stop);
  "check", Luv.Check.(for_watcher_kind init start stop);
  "idle", Luv.Check.(for_watcher_kind init start stop);
]