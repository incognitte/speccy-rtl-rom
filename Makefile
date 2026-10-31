PY     ?= python3
SJ_TAG := v1.24.0
SJ     := $(shell command -v sjasmplus 2>/dev/null || echo .sjasmplus/sjasmplus)

.PHONY: arabic persian clean distclean edit-persian check-persian genlang genflags

arabic: $(SJ)
	mkdir -p build
	$(SJ) --raw=build/48k_ARABIC.ROM main.asm

persian: $(SJ)
	mkdir -p build
	$(SJ) -DLANG_PERSIAN --raw=build/48k_PERSIAN.ROM main.asm

edit-persian:
	$(PY) tools/persian_editor.py

check-persian:
	$(PY) tools/persian_editor.py --check

genlang:
	$(PY) tools/genlang.py

genflags: genlang
	$(PY) tools/genflags.py

.sjasmplus/sjasmplus:
	git clone --depth 1 --branch $(SJ_TAG) https://github.com/z00m128/sjasmplus .sjasmplus-src
	$(MAKE) -C .sjasmplus-src USE_LUA=0
	mkdir -p .sjasmplus
	cp .sjasmplus-src/sjasmplus .sjasmplus/

clean:
	rm -rf build
distclean: clean
	rm -rf .sjasmplus .sjasmplus-src
