// mayhem/kat/main.go — dynamically-linked known-answer probe for
// workloadspread.NestedField. `import "C"` (cgo) forces a dynamically linked binary so the
// gate's LD_PRELOAD sabotage shim can neuter it (a static Go binary would be immune).
//
// It imports the package staged by mayhem/build.sh at _mayhem_harness/pkg/util/workloadspread, runs KATNested()
// and prints each result in a fixed format for mayhem/test.sh to assert.
package main

// #include <stdint.h>
import "C"

import (
	"fmt"
	"os"

	ws "github.com/openkruise/kruise/_mayhem_harness/pkg/util/workloadspread"
)

func main() {
	results, err := ws.KATNested()
	if err != nil {
		fmt.Fprintf(os.Stderr, "KAT error: %v\n", err)
		os.Exit(1)
	}
	for i, r := range results {
		fmt.Printf("KAT_%d_PATH=%s\n", i, r.Name)
		fmt.Printf("KAT_%d_OUT=%s\n", i, r.Out)
	}
}
