package v0compiler

import "core:fmt"
import "core:time"

// TODO: module that takes benchmarks at specific markers,
// reruns main multiple times and calculates averages for every pass


// result printing or sumth
COLOR_RESET   :: "\x1b[0m"
COLOR_RED     :: "\x1b[31m"
COLOR_BOLD_GREEN   :: "\x1b[1;32m"
COLOR_GREEN   :: "\x1b[32m"
COLOR_BOLD_YELLOW   :: "\x1b[1;33m"
COLOR_YELLOW  :: "\x1b[33m"

Timer :: struct {
	start: [dynamic]time.Tick,
	end:   [dynamic]time.Tick,
}


Benchmarks :: struct {
	timers: [dynamic]Timer,
    timer_names: [dynamic]string,
}

benchmarks : Benchmarks

start_benchmark :: proc(name: string) -> u8 {
    for i:u8=0; i<cast(u8)len(benchmarks.timer_names); {
        if name == benchmarks.timer_names[i] {
            return i
        }
    }
    append_elem(&benchmarks.timer_names, name)
    timer : Timer

    append_elem(&benchmarks.timers, timer)

    i: = cast(u8)len(benchmarks.timer_names)-1
    append_elem(&benchmarks.timers[i].start, time.tick_now())
    append_elem(&benchmarks.timers[i].end, time.tick_now())

    return i
}

end_benchmark :: proc(timer_id: u8, iteration: u8) {
    benchmarks.timers[timer_id].end[iteration] = time.tick_now()
}

print_benchmarks :: proc() {

    i := 0
    total_tokenizer := cast(time.Duration)0
    total_parser := cast(time.Duration)0

    for i<len(benchmarks.timers) {
        t := 0 

        for t<len(benchmarks.timers) {
            elapsed := time.tick_diff(benchmarks.timers[i].start[t], benchmarks.timers[i].end[t])
            total_parser += elapsed 

            t += 1
        }
        ti := cast(f32)t
        ok := fmt.printfln("\n  %s %s file%s in:  %.9fs", COLOR_BOLD_YELLOW, benchmarks.timer_names[i], COLOR_RESET, cast(f32)total_tokenizer/ti)
    }
}


