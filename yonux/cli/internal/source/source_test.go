package source

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadWithoutRecordIsEmpty(t *testing.T) {
	s, err := Load(t.TempDir())
	if err != nil || s != (Source{}) {
		t.Fatalf("Load = %+v, %v; want empty", s, err)
	}
}

func TestSaveThenLoad(t *testing.T) {
	state := filepath.Join(t.TempDir(), "state", "yonux")
	if err := Save(state, Source{Checkout: "/home/me/yonux"}); err != nil {
		t.Fatal(err)
	}
	if err := Save(state, Source{Checkout: "/home/me/other"}); err != nil {
		t.Fatal(err)
	}
	s, err := Load(state)
	if err != nil || s.Checkout != "/home/me/other" {
		t.Fatalf("Load = %+v, %v", s, err)
	}
}

func TestLoadRejectsBadRecords(t *testing.T) {
	for _, body := range []string{"{", "null", "[]", `{}`, `{"checkout":""}`, `{"checkout":"relative/clone"}`} {
		t.Run(body, func(t *testing.T) {
			state := t.TempDir()
			if err := os.WriteFile(filepath.Join(state, "source.json"), []byte(body), 0o644); err != nil {
				t.Fatal(err)
			}
			if _, err := Load(state); err == nil {
				t.Fatal("Load accepted an invalid record")
			}
		})
	}
}
