"""
test_game_logic.py — Suite de pruebas
Ejecutar: python test_game_logic.py
"""
from game_logic import (
    GameController, GameState, EventBus, EventListener,
    Clue, Puzzle, ProgressTracker, ArrayList, HashMap, RandomLCG,
    STAGE_LOCKED, STAGE_INTRO, STAGE_MIDWAY,
    STAGE_ADVANCED, STAGE_FINAL, STAGE_COMPLETE,
)

ok = 0
fail = 0

def h(t):
    print("\n" + "="*54)
    print("  " + t)
    print("="*54)

def c(label, cond):
    global ok, fail
    if cond:
        print("  OK    " + label)
        ok += 1
    else:
        print("  FALLO " + label)
        fail += 1

class TL(EventListener):
    def __init__(self):
        self.evs = ArrayList()
    def on_event(self, name, data):
        self.evs.append(name)
    def got(self, name):
        return self.evs.contains(name)

# ── RandomLCG ───────────────────────────────────────────────
h("RandomLCG — componente aleatorio")
r = RandomLCG()
a = r.next_int()
b = r.next_int()
c("next_int genera enteros distintos", a != b)
x = r.next_range(0, 5)
c("next_range [0,5) en rango",  0 <= x < 5)
c("next_range low==high = low", r.next_range(3,3) == 3)

# ── ArrayList ───────────────────────────────────────────────
h("ArrayList")
al = ArrayList()
c("inicia vacio",        al.is_empty())
c("size = 0",            al.size == 0)
al.append("a")
al.append("b")
al.append("c")
c("size = 3",            al.size == 3)
c("get(0) = 'a'",        al.get(0) == "a")
c("get(2) = 'c'",        al.get(2) == "c")
c("contains 'b'",        al.contains("b"))
c("index_of 'c' = 2",    al.index_of("c") == 2)
c("index_of 'z' = -1",   al.index_of("z") == -1)
al.set(1, "B")
c("set(1,'B') funciona", al.get(1) == "B")
al.remove_value("B")
c("remove_value funciona", al.size == 2)
c("no contiene 'B'",     not al.contains("B"))
try:
    al.get(99)
    c("IndexError fuera de rango", False)
except IndexError:
    c("IndexError fuera de rango", True)
# Probar crecimiento dinamico (mas de 8 elementos)
al2 = ArrayList()
for i in range(20):
    al2.append(i)
c("crecimiento dinamico (20 elem)", al2.size == 20)
c("valores correctos tras resize",  al2.get(15) == 15)

# ── HashMap ─────────────────────────────────────────────────
h("HashMap")
hm = HashMap()
c("inicia vacio",        hm.is_empty())
hm.put("x", 10)
hm.put("y", 20)
hm.put("z", 30)
c("size = 3",            hm.size == 3)
c("get 'x' = 10",        hm.get("x") == 10)
c("get 'y' = 20",        hm.get("y") == 20)
c("contains_key 'z'",    hm.contains_key("z"))
c("get default",         hm.get("no", 99) == 99)
hm.put("x", 99)
c("update clave existente", hm.get("x") == 99)
hm.remove("y")
c("remove funciona",     not hm.contains_key("y"))
c("size = 2",            hm.size == 2)
ks = hm.keys()
c("keys retorna ArrayList", ks.size == 2)
vs = hm.values()
c("values retorna ArrayList", vs.size == 2)
# Probar rehash (mas de 12 elementos en 16 buckets)
hm2 = HashMap()
for i in range(15):
    hm2.put("k" + str(i), i)
c("rehash: size 15",     hm2.size == 15)
c("rehash: valores ok",  hm2.get("k7") == 7)

# ── TAD 1: Clue ─────────────────────────────────────────────
h("TAD 1 — Clue")
cl = Clue("clue1", "Archivo", "Busca letras.")
c("inicia no colectada",  not cl.collected)
c("value inicia None",    cl.value is None)
cl.collect("C")
c("colectada correctamente", cl.collected)
c("value = 'C'",          cl.value == "C")
cl.reset()
c("reset limpia",         not cl.collected and cl.value is None)
try:
    Clue("", "L", "H")
    c("ValueError key vacio", False)
except ValueError:
    c("ValueError key vacio", True)
try:
    Clue("k","l","h").collect("")
    c("ValueError collect vacio", False)
except ValueError:
    c("ValueError collect vacio", True)

# ── TAD 2: Puzzle ────────────────────────────────────────────
h("TAD 2 — Puzzle (componente aleatorio)")
hints = ArrayList()
hints.append("Pista A")
hints.append("Pista B")
hints.append("Pista C")
p = Puzzle("p1","clue1","respuesta","Desc",hints)
c("inicia no resuelto",   not p.solved)
c("intentos = 0",         p.attempts == 0)
c("respuesta vacia = F",  not p.check_answer(""))
c("respuesta mala = F",   not p.check_answer("mal"))
c("intento registrado",   p.attempts == 1)
c("respuesta ok = True",  p.check_answer("respuesta"))
c("marcado resuelto",     p.solved)
hint = p.get_random_hint()
c("get_random_hint string", isinstance(hint, str) and len(hint) > 0)
p.reset()
c("reset limpia",         not p.solved and p.attempts == 0)
try:
    Puzzle("","c","a","d",ArrayList())
    c("ValueError puzzle_id vacio", False)
except ValueError:
    c("ValueError puzzle_id vacio", True)

# ── TAD 3: ProgressTracker ───────────────────────────────────
h("TAD 3 — ProgressTracker")
cl_list = ArrayList()
cl_list.append(Clue("c1","L1","h1"))
cl_list.append(Clue("c2","L2","h2"))
pt = ProgressTracker(cl_list)
c("etapa inicial LOCKED",  pt.stage == STAGE_LOCKED)
c("collected = 0",         pt.collected_count() == 0)
pt.advance_stage(STAGE_INTRO)
c("advance_stage ok",      pt.stage == STAGE_INTRO)
pt.collect_clue("c1","v1")
c("has_clue c1",           pt.has_clue("c1"))
c("collected = 1",         pt.collected_count() == 1)
c("all_collected F",       not pt.all_collected())
pt.collect_clue("c2","v2")
c("all_collected T",       pt.all_collected())
c("historial no vacio",    not pt.get_history().is_empty())
try:
    ProgressTracker(ArrayList())
    c("ValueError clues vacio", False)
except ValueError:
    c("ValueError clues vacio", True)

# ── TAD 4: EventBus ─────────────────────────────────────────
h("TAD 4 — EventBus (Observer)")
bus = EventBus()
tl  = TL()
bus.subscribe("ev", tl)
bus.publish("ev", HashMap())
c("listener recibe evento",  tl.got("ev"))
bus.unsubscribe("ev", tl)
tl.evs = ArrayList()
bus.publish("ev", HashMap())
c("no recibe tras unsub",    not tl.got("ev"))

# ── T9/T13 ──────────────────────────────────────────────────
h("T9/T13 — Bloqueo / Contrasena inicial")
gc  = GameController()
tl2 = TL()
gc.subscribe("phone_unlocked", tl2)
gc.subscribe("error_occurred",  tl2)
c("inicia bloqueado",          gc.is_phone_locked())
c("pwd vacia falla",           not gc.unlock_phone(""))
c("error generado",            gc.state.error_message is not None)
c("observer error_occurred",   tl2.got("error_occurred"))
c("pwd incorrecta falla",      not gc.unlock_phone("1234"))
c("pwd correcta pasa",         gc.unlock_phone("alex"))
c("etapa INTRO",               gc.get_stage() == STAGE_INTRO)
c("observer phone_unlocked",   tl2.got("phone_unlocked"))
c("ya no bloqueado",           not gc.is_phone_locked())

# ── T8 ──────────────────────────────────────────────────────
h("T8 — Navegacion entre apps")
c("abre mensajes",             gc.open_app("mensajes"))
c("app activa = mensajes",     gc.state.current_app == "mensajes")
gc.go_home()
c("go_home limpia app",        gc.state.current_app is None)
c("red_social bloqueada",      not gc.open_app("red_social"))
c("error al intentar",         gc.state.error_message is not None)
c("app inexistente falla",     not gc.open_app("calculadora"))
c("diario bloqueado",          not gc.open_app("diario"))

# ── T12 ─────────────────────────────────────────────────────
h("T12 — Desbloqueo de contenido")
apps = gc.get_available_apps()
c("mensajes en INTRO",         apps.contains("mensajes"))
c("archivos en INTRO",         apps.contains("archivos"))
c("red_social NO en INTRO",    not apps.contains("red_social"))
c("diario NO en INTRO",        not apps.contains("diario"))
c("is_app_unlocked mensajes",  gc.is_app_unlocked("mensajes"))
c("is_app_unlocked diario F",  not gc.is_app_unlocked("diario"))

# ── T16/T10 ─────────────────────────────────────────────────
h("T16/T10 — Puzzles y pistas")
tl3 = TL()
gc.subscribe("clue_collected", tl3)
c("puzzle vacio falla",        not gc.submit_puzzle_answer("clue1",""))
c("puzzle clave invalida",     not gc.submit_puzzle_answer("clue_x","X"))
c("pista 1 incorrecta",        not gc.submit_puzzle_answer("clue1","Z"))
c("error generado",            gc.state.error_message is not None)
c("pista 1 correcta",          gc.submit_puzzle_answer("clue1","C"))
c("observer clue_collected",   tl3.got("clue_collected"))
c("etapa MIDWAY",              gc.get_stage() == STAGE_MIDWAY)
c("has_clue clue1",            gc.has_clue("clue1"))
c("collected = 1",             gc.state.tracker.collected_count() == 1)
c("red_social disponible",     gc.is_app_unlocked("red_social"))
c("pista 2 correcta",          gc.submit_puzzle_answer("clue2","iber"))
c("etapa ADVANCED",            gc.get_stage() == STAGE_ADVANCED)
c("pista 3 correcta",          gc.submit_puzzle_answer("clue3","acoso"))
c("etapa FINAL",               gc.get_stage() == STAGE_FINAL)
c("is_final_lock_active",      gc.is_final_lock_active())
ccs = gc.get_collected_clues()
c("get_collected_clues = 3",   ccs.size == 3)

# ── T14 ─────────────────────────────────────────────────────
h("T14 — Contrasena final")
c("final vacia falla",         not gc.submit_final_password(""))
c("final incorrecta falla",    not gc.submit_final_password("wrong"))
c("error generado",            gc.state.error_message is not None)
c("final correcta pasa",       gc.submit_final_password("Ciberacoso"))
c("juego completo",            gc.is_game_complete())
c("diario desbloqueado",       gc.is_app_unlocked("diario"))

h("T14 — Final antes de tiempo")
gc2 = GameController()
gc2.unlock_phone("alex")
c("final falla sin pistas",    not gc2.submit_final_password("Ciberacoso"))
c("error etapa incorrecta",    gc2.state.error_message is not None)

# ── T11 ─────────────────────────────────────────────────────
h("T11 — Estado del juego")
s = gc.get_state_summary()
c("summary es HashMap",        isinstance(s, HashMap))
c("summary tiene stage",       s.contains_key("stage"))
c("summary tiene progress",    s.contains_key("progress"))
c("summary tiene error",       s.contains_key("error"))

# ── AYUDA ───────────────────────────────────────────────────
h("AYUDA — Usabilidad")
gc3 = GameController()
hl  = gc3.request_help()
c("ayuda LOCKED es str",       isinstance(hl, str) and len(hl) > 0)
gc3.unlock_phone("alex")
hi  = gc3.request_help()
c("ayuda INTRO es str",        isinstance(hi, str) and len(hi) > 0)
c("textos distintos",          hl != hi)
hnt = gc3.get_puzzle_hint("clue1")
c("get_puzzle_hint str",       isinstance(hnt, str) and len(hnt) > 0)

print("\n" + "="*54)
print("  Resultado: " + str(ok) + " OK   " + str(fail) + " FALLOS")
print("="*54 + "\n")
