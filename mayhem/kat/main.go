// mayhem/kat/main.go — dynamically-linked known-answer probe for the openkruise
// resource-expression calculator. `import "C"` (cgo) forces a DYNAMICALLY LINKED
// binary so the LD_PRELOAD sabotage shim used by the gate's anti-reward-hacking
// check can neuter it (a statically-linked Go binary would be immune, giving a
// false-green oracle — exactly the trap netnew §4 warns about with `go test`
// alone).
//
// It imports the build-time-staged package (created by mayhem/build.sh at
// _mayhem_harness/calc) and runs KATParses(), which parses fixed expressions
// through the real Parse()/GetResult() path, then prints each result in a fixed,
// greppable format for mayhem/test.sh to assert.
package main

// #include <stdint.h>
import "C"

import (
	"fmt"
	"os"

	calc "github.com/openkruise/kruise/_mayhem_harness/calc"
)

func main() {
	results, err := calc.KATParses()
	if err != nil {
		fmt.Fprintf(os.Stderr, "KAT error: %v\n", err)
		os.Exit(1)
	}
	for i, r := range results {
		fmt.Printf("KAT_%d_EXPR=%s\n", i, r.Expr)
		fmt.Printf("KAT_%d_OUT=%s\n", i, r.Out)
	}
}
