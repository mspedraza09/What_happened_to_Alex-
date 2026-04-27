import time
from abc import ABC, abstractmethod


# ─────────────────────────────────────────────────────────────
#  GENERADOR PSEUDO-ALEATORIO (LCG) — sin modulo random
#  Componente aleatorio del juego implementado desde cero.
# ─────────────────────────────────────────────────────────────

class RandomLCG:
    _A = 1664525
    _C = 1013904223
    _M = 2 ** 32

    def __init__(self):
        self._state = int(time.time() * 1000) % self._M

    def next_int(self):
        self._state = (self._A * self._state + self._C) % self._M
        return self._state

    def next_range(self, low, high):
        if high <= low:
            return low
        return low + (self.next_int() % (high - low))

_rng = RandomLCG()


# ─────────────────────────────────────────────────────────────
#  ArrayList — arreglo dinamico manual (sin list)
# ─────────────────────────────────────────────────────────────

class ArrayList:
    _INIT_CAP = 8

    def __init__(self):
        self._cap  = self._INIT_CAP
        self._data = (None,) * self._cap
        self._size = 0

    def append(self, val):
        if self._size == self._cap:
            self._grow()
        self._data = self._data[:self._size] + (val,) + self._data[self._size+1:]
        self._size += 1

    def get(self, idx):
        self._check(idx)
        return self._data[idx]

    def set(self, idx, val):
        self._check(idx)
        self._data = self._data[:idx] + (val,) + self._data[idx+1:]

    def remove_value(self, val):
        for i in range(self._size):
            if self._data[i] == val:
                self._data = self._data[:i] + self._data[i+1:self._size] + (None,)
                self._size -= 1
                return True
        return False

    def contains(self, val):
        for i in range(self._size):
            if self._data[i] == val:
                return True
        return False

    def index_of(self, val):
        for i in range(self._size):
            if self._data[i] == val:
                return i
        return -1

    @property
    def size(self):
        return self._size

    def is_empty(self):
        return self._size == 0

    def _grow(self):
        self._data = self._data + (None,) * self._cap
        self._cap *= 2

    def _check(self, idx):
        if idx < 0 or idx >= self._size:
            raise IndexError(f"Indice {idx} fuera de rango (size={self._size})")

    def __iter__(self):
        self._it = 0
        return self

    def __next__(self):
        if self._it >= self._size:
            raise StopIteration
        v = self._data[self._it]
        self._it += 1
        return v

    def __repr__(self):
        s = ""
        for i in range(self._size):
            s += str(self._data[i])
            if i < self._size - 1:
                s += ", "
        return "ArrayList[" + s + "]"


# ─────────────────────────────────────────────────────────────
#  HashMap — tabla hash con encadenamiento (sin dict)
# ─────────────────────────────────────────────────────────────

class _Node:
    def __init__(self, key, val):
        self.key  = key
        self.val  = val
        self.next = None

class HashMap:
    _INIT_BUCKETS = 16
    _MAX_LOAD     = 0.75

    def __init__(self):
        self._n_buckets = self._INIT_BUCKETS
        self._buckets   = (None,) * self._n_buckets
        self._size      = 0

    def _hash(self, key):
        h = 5381
        for ch in str(key):
            h = ((h << 5) + h + ord(ch)) & 0xFFFFFFFF
        return h % self._n_buckets

    def put(self, key, val):
        if self._size / self._n_buckets >= self._MAX_LOAD:
            self._rehash()
        idx  = self._hash(key)
        node = self._buckets[idx]
        while node:
            if node.key == key:
                node.val = val
                return
            node = node.next
        new  = _Node(key, val)
        new.next = self._buckets[idx]
        self._buckets = self._buckets[:idx] + (new,) + self._buckets[idx+1:]
        self._size += 1

    def get(self, key, default=None):
        node = self._buckets[self._hash(key)]
        while node:
            if node.key == key:
                return node.val
            node = node.next
        return default

    def remove(self, key):
        idx  = self._hash(key)
        node = self._buckets[idx]
        prev = None
        while node:
            if node.key == key:
                if prev:
                    prev.next = node.next
                else:
                    self._buckets = self._buckets[:idx] + (node.next,) + self._buckets[idx+1:]
                self._size -= 1
                return True
            prev, node = node, node.next
        return False

    def contains_key(self, key):
        node = self._buckets[self._hash(key)]
        while node:
            if node.key == key:
                return True
            node = node.next
        return False

    def keys(self):
        out = ArrayList()
        for i in range(self._n_buckets):
            node = self._buckets[i]
            while node:
                out.append(node.key)
                node = node.next
        return out

    def values(self):
        out = ArrayList()
        for i in range(self._n_buckets):
            node = self._buckets[i]
            while node:
                out.append(node.val)
                node = node.next
        return out

    @property
    def size(self):
        return self._size

    def is_empty(self):
        return self._size == 0

    def _rehash(self):
        old, old_n = self._buckets, self._n_buckets
        self._n_buckets *= 2
        self._buckets    = (None,) * self._n_buckets
        self._size       = 0
        for i in range(old_n):
            node = old[i]
            while node:
                self.put(node.key, node.val)
                node = node.next

    def __repr__(self):
        s = ""
        first = True
        for i in range(self._n_buckets):
            node = self._buckets[i]
            while node:
                if not first:
                    s += ", "
                s += str(node.key) + ": " + str(node.val)
                first = False
                node = node.next
        return "HashMap{" + s + "}"


# ─────────────────────────────────────────────────────────────
#  CONSTANTES DEL JUEGO
# ─────────────────────────────────────────────────────────────

STAGE_LOCKED   = "locked"
STAGE_INTRO    = "intro"
STAGE_MIDWAY   = "midway"
STAGE_ADVANCED = "advanced"
STAGE_FINAL    = "final_lock"
STAGE_COMPLETE = "complete"

_STAGE_ORDER = ArrayList()
_STAGE_ORDER.append(STAGE_LOCKED)
_STAGE_ORDER.append(STAGE_INTRO)
_STAGE_ORDER.append(STAGE_MIDWAY)
_STAGE_ORDER.append(STAGE_ADVANCED)
_STAGE_ORDER.append(STAGE_FINAL)
_STAGE_ORDER.append(STAGE_COMPLETE)

def _stage_idx(stage):
    return _STAGE_ORDER.index_of(stage)

INITIAL_PASSWORD = "alex"
FINAL_PASSWORD   = "ciberacoso"

APP_UNLOCK_STAGE = HashMap()
APP_UNLOCK_STAGE.put("mensajes",   STAGE_INTRO)
APP_UNLOCK_STAGE.put("archivos",   STAGE_INTRO)
APP_UNLOCK_STAGE.put("galeria",    STAGE_INTRO)
APP_UNLOCK_STAGE.put("buscador",   STAGE_INTRO)
APP_UNLOCK_STAGE.put("red_social", STAGE_MIDWAY)
APP_UNLOCK_STAGE.put("notas",      STAGE_MIDWAY)
APP_UNLOCK_STAGE.put("diario",     STAGE_COMPLETE)

_MOTIVATIONAL = ArrayList()
_MOTIVATIONAL.append("Buen ojo! Cada detalle cuenta.")
_MOTIVATIONAL.append("Vas por buen camino! Sigue investigando.")
_MOTIVATIONAL.append("Excelente! Una pieza mas del rompecabezas.")
_MOTIVATIONAL.append("Increible! Alex cuenta contigo.")
_MOTIVATIONAL.append("Eso es! La verdad se esta revelando.")

_WRONG_PWD = ArrayList()
_WRONG_PWD.append("Contrasena incorrecta. Revisa las pistas de la carta.")
_WRONG_PWD.append("Eso no es correcto. Lee la carta con cuidado.")
_WRONG_PWD.append("Intenta de nuevo. La respuesta esta en la carta.")

_HELP = HashMap()
_HELP.put(STAGE_LOCKED,
    "AYUDA - Bloqueo\nEl telefono esta bloqueado. La carta contiene la clave.\nInterprétala, no es directa.")
_HELP.put(STAGE_INTRO,
    "AYUDA - Primera etapa\nExplora: Mensajes, Archivos, Galeria, Buscador.\nBusca letras resaltadas en el archivo de Alex.")
_HELP.put(STAGE_MIDWAY,
    "AYUDA - Segunda etapa\nRed Social y Notas ya disponibles.\nUn perfil del buscador es distinto. Usa el cifrado Cesar.")
_HELP.put(STAGE_ADVANCED,
    "AYUDA - Tercera etapa\nUn apodo ofensivo aparece censurado en chats y red social.\nReconstruye la palabra completa.")
_HELP.put(STAGE_FINAL,
    "AYUDA - Contrasena final\nUne las 3 pistas para formar la contrasena.")
_HELP.put(STAGE_COMPLETE,
    "El diario de Alex esta desbloqueado. Lee su historia.")

def _rand_pick(arr):
    if arr.is_empty():
        return ""
    return arr.get(_rng.next_range(0, arr.size))


# ─────────────────────────────────────────────────────────────
#  PATRON OBSERVER
# ─────────────────────────────────────────────────────────────

class EventListener(ABC):
    @abstractmethod
    def on_event(self, event_name, data):
        pass


class EventBus:
    """TAD 4 — Patron Observer. Usa HashMap<str, ArrayList>."""

    def __init__(self):
        self._ls = HashMap()   # HashMap<event_name, ArrayList<listener>>

    def subscribe(self, event_name, listener):
        if not self._ls.contains_key(event_name):
            self._ls.put(event_name, ArrayList())
        arr = self._ls.get(event_name)
        if not arr.contains(listener):
            arr.append(listener)

    def unsubscribe(self, event_name, listener):
        if self._ls.contains_key(event_name):
            self._ls.get(event_name).remove_value(listener)

    def publish(self, event_name, data=None):
        if data is None:
            data = HashMap()
        if not self._ls.contains_key(event_name):
            return
        for listener in self._ls.get(event_name):
            try:
                listener.on_event(event_name, data)
            except Exception:
                pass


# ─────────────────────────────────────────────────────────────
#  TAD 1 — Clue
# ─────────────────────────────────────────────────────────────

class Clue:
    def __init__(self, key, label, hint):
        if not key or not label:
            raise ValueError("Clue requiere key y label.")
        self._key       = key
        self._label     = label
        self._hint      = hint
        self._value     = None
        self._collected = False

    @property
    def key(self):        return self._key
    @property
    def label(self):      return self._label
    @property
    def hint(self):       return self._hint
    @property
    def value(self):      return self._value
    @property
    def collected(self):  return self._collected

    def collect(self, value):
        if not value or not value.strip():
            raise ValueError("Valor de pista no puede estar vacio.")
        self._value     = value.strip()
        self._collected = True

    def reset(self):
        self._value     = None
        self._collected = False

    def to_map(self):
        m = HashMap()
        m.put("key",       self._key)
        m.put("label",     self._label)
        m.put("collected", self._collected)
        m.put("value",     self._value)
        return m

    def __repr__(self):
        s = "'" + self._value + "'" if self._collected else "pendiente"
        return "Clue(" + self._key + ", " + s + ")"


# ─────────────────────────────────────────────────────────────
#  TAD 2 — Puzzle  (componente aleatorio via LCG)
# ─────────────────────────────────────────────────────────────

class Puzzle:
    def __init__(self, puzzle_id, clue_key, answer,
                 description, hints, max_attempts=3):
        if not puzzle_id or not answer:
            raise ValueError("Puzzle requiere puzzle_id y answer.")
        if max_attempts < 1:
            raise ValueError("max_attempts >= 1.")
        self._pid   = puzzle_id
        self._ckey  = clue_key
        self._ans   = answer.strip().lower()
        self._desc  = description
        self._hints = hints if hints is not None else ArrayList()
        self._maxat = max_attempts
        self._tries = 0
        self._solved = False

    @property
    def puzzle_id(self):      return self._pid
    @property
    def clue_key(self):       return self._ckey
    @property
    def description(self):    return self._desc
    @property
    def attempts(self):       return self._tries
    @property
    def solved(self):         return self._solved
    @property
    def needs_extra_help(self): return self._tries >= self._maxat and not self._solved

    def check_answer(self, answer):
        if self._solved:
            return True
        if not answer or not answer.strip():
            return False
        self._tries += 1
        if answer.strip().lower() == self._ans:
            self._solved = True
            return True
        return False

    def get_random_hint(self):
        """COMPONENTE ALEATORIO — LCG propio."""
        return _rand_pick(self._hints) if not self._hints.is_empty() else "Sigue investigando."

    def reset(self):
        self._tries  = 0
        self._solved = False

    def to_map(self):
        m = HashMap()
        m.put("puzzle_id",   self._pid)
        m.put("clue_key",    self._ckey)
        m.put("description", self._desc)
        m.put("attempts",    self._tries)
        m.put("solved",      self._solved)
        return m

    def __repr__(self):
        s = "OK" if self._solved else "(" + str(self._tries) + " intentos)"
        return "Puzzle(" + self._pid + ", " + s + ")"


# ─────────────────────────────────────────────────────────────
#  TAD 3 — ProgressTracker  (SOLID SRP)
# ─────────────────────────────────────────────────────────────

class ProgressTracker:
    """Rastrea etapa y pistas. HashMap<key,Clue> + ArrayList historial."""

    def __init__(self, clues):
        if clues is None or clues.is_empty():
            raise ValueError("ProgressTracker necesita al menos una pista.")
        self._clues   = HashMap()
        for c in clues:
            self._clues.put(c.key, c)
        self._stage   = STAGE_LOCKED
        self._history = ArrayList()

    @property
    def stage(self):  return self._stage

    def advance_stage(self, new_stage):
        if _stage_idx(new_stage) == -1:
            raise ValueError("Etapa desconocida: " + new_stage)
        if _stage_idx(new_stage) <= _stage_idx(self._stage):
            return
        self._stage = new_stage
        self._history.append("Etapa -> " + new_stage)

    def collect_clue(self, clue_key, value):
        if not self._clues.contains_key(clue_key):
            raise KeyError("Pista '" + clue_key + "' no existe.")
        self._clues.get(clue_key).collect(value)
        self._history.append("Pista: " + clue_key + "='" + value + "'")

    def get_clue(self, clue_key):
        return self._clues.get(clue_key, None)

    def all_clues(self):
        return self._clues.values()

    def collected_count(self):
        n = 0
        for c in self._clues.values():
            if c.collected:
                n += 1
        return n

    def all_collected(self):
        for c in self._clues.values():
            if not c.collected:
                return False
        return True

    def has_clue(self, key):
        c = self._clues.get(key, None)
        return c is not None and c.collected

    def get_history(self):
        return self._history

    def summary(self):
        m = HashMap()
        m.put("stage",     self._stage)
        m.put("collected", self.collected_count())
        m.put("total",     self._clues.size)
        return m

    def __repr__(self):
        return ("ProgressTracker(stage=" + self._stage +
                ", clues=" + str(self.collected_count()) +
                "/" + str(self._clues.size) + ")")


# ─────────────────────────────────────────────────────────────
#  TAD 5 — GameState
# ─────────────────────────────────────────────────────────────

class GameState:
    """Estado completo. Usa HashMap y ArrayList propios en todo."""

    def __init__(self):
        clues = ArrayList()
        clues.append(Clue("clue1", "Archivo de trabajo",
                          "Letras resaltadas en el archivo de criptografia."))
        clues.append(Clue("clue2", "Mensaje cifrado",
                          "Usa el cifrado Cesar del archivo."))
        clues.append(Clue("clue3", "Apodo de Alex",
                          "Apodo censurado en chats/red social."))

        h1 = ArrayList()
        h1.append("Abre Archivos y busca el documento de criptografia.")
        h1.append("Las letras resaltadas estan en el texto del archivo.")
        h1.append("Solo una letra esta destacada.")

        h2 = ArrayList()
        h2.append("Recuerda el cifrado Cesar del archivo.")
        h2.append("Desplaza cada letra el numero indicado.")
        h2.append("El mensaje esta en el perfil diferente del buscador.")

        h3 = ArrayList()
        h3.append("El apodo aparece en chats y red social.")
        h3.append("Letras censuradas con asteriscos.")
        h3.append("Identifica el patron y reconstruye la palabra.")

        self._puzzles = HashMap()
        self._puzzles.put("puzzle1", Puzzle(
            "puzzle1","clue1","C",
            "Letras resaltadas en el archivo de trabajo.", h1))
        self._puzzles.put("puzzle2", Puzzle(
            "puzzle2","clue2","iber",
            "Descifra el mensaje del perfil inusual.", h2))
        self._puzzles.put("puzzle3", Puzzle(
            "puzzle3","clue3","acoso",
            "Reconstruye el apodo de Alex.", h3))

        self._tracker  = ProgressTracker(clues)
        self._cur_app  = None
        self._err_msg  = None
        self._fb_msg   = None

    @property
    def tracker(self):    return self._tracker
    @property
    def stage(self):      return self._tracker.stage
    @property
    def current_app(self): return self._cur_app
    @property
    def error_message(self): return self._err_msg
    @property
    def last_feedback(self): return self._fb_msg

    def set_current_app(self, app): self._cur_app = app
    def set_error(self, m):   self._err_msg = m;  self._fb_msg = None
    def set_feedback(self, m): self._fb_msg = m;  self._err_msg = None
    def clear_messages(self):  self._err_msg = None; self._fb_msg = None

    def get_puzzle_by_clue(self, clue_key):
        for p in self._puzzles.values():
            if p.clue_key == clue_key:
                return p
        return None

    def full_summary(self):
        m = HashMap()
        m.put("stage",       self.stage)
        m.put("current_app", self._cur_app)
        m.put("error",       self._err_msg)
        m.put("feedback",    self._fb_msg)
        m.put("progress",    self._tracker.summary())
        return m


# ─────────────────────────────────────────────────────────────
#  TAD 6 — GameController (Facade + SOLID DIP)
# ─────────────────────────────────────────────────────────────

class GameController:
    """Punto de entrada unico para UI (ANNY) y apps (Maria)."""

    def __init__(self, state=None, event_bus=None):
        self.state = state or GameState()
        self.bus   = event_bus or EventBus()

    def _pub(self, event, **kv):
        d = HashMap()
        for k, v in kv.items():
            d.put(k, v)
        self.bus.publish(event, d)

    # T9/T13
    def unlock_phone(self, password):
        self.state.clear_messages()
        if not password or not password.strip():
            msg = "Debes ingresar una contrasena."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="unlock")
            return False
        if password.strip().lower() == INITIAL_PASSWORD:
            self.state.tracker.advance_stage(STAGE_INTRO)
            self._pub("phone_unlocked", stage=STAGE_INTRO)
            self._pub("stage_changed", new_stage=STAGE_INTRO)
            return True
        msg = _rand_pick(_WRONG_PWD)
        self.state.set_error(msg)
        self._pub("error_occurred", message=msg, source="unlock")
        return False

    # T8
    def open_app(self, app_name):
        self.state.clear_messages()
        if self.state.stage == STAGE_LOCKED:
            msg = "Primero desbloquea el telefono."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="nav")
            return False
        if not APP_UNLOCK_STAGE.contains_key(app_name):
            msg = "La app '" + app_name + "' no existe."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="nav")
            return False
        req = APP_UNLOCK_STAGE.get(app_name)
        if _stage_idx(self.state.stage) < _stage_idx(req):
            msg = "'" + app_name + "' no disponible todavia."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="nav")
            return False
        self.state.set_current_app(app_name)
        self._pub("app_opened", app=app_name)
        return True

    def go_home(self):
        prev = self.state.current_app
        self.state.set_current_app(None)
        self.state.clear_messages()
        self._pub("app_closed", previous_app=str(prev))

    def close_app(self):
        self.go_home()

    # T12
    def get_available_apps(self):
        out = ArrayList()
        cur = _stage_idx(self.state.stage)
        for app in APP_UNLOCK_STAGE.keys():
            if cur >= _stage_idx(APP_UNLOCK_STAGE.get(app)):
                out.append(app)
        return out

    def is_app_unlocked(self, app_name):
        if not APP_UNLOCK_STAGE.contains_key(app_name):
            return False
        return (_stage_idx(self.state.stage) >=
                _stage_idx(APP_UNLOCK_STAGE.get(app_name)))

    # T16
    def submit_puzzle_answer(self, clue_key, answer):
        self.state.clear_messages()
        puzzle = self.state.get_puzzle_by_clue(clue_key)
        if puzzle is None:
            msg = "Puzzle '" + clue_key + "' no reconocido."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="puzzle")
            return False
        if not answer or not answer.strip():
            msg = "Debes ingresar una respuesta."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="puzzle")
            return False
        if self.state.tracker.has_clue(clue_key):
            self.state.set_feedback("Ya tienes esta pista!")
            return True
        if puzzle.check_answer(answer):
            self.state.tracker.collect_clue(clue_key, answer.strip())
            self.state.set_feedback(_rand_pick(_MOTIVATIONAL))
            self._pub("clue_collected", clue_key=clue_key,
                      value=answer.strip(),
                      total=self.state.tracker.collected_count())
            self._advance()
            return True
        hint = puzzle.get_random_hint()
        msg  = "Incorrecto. Pista: " + hint
        self.state.set_error(msg)
        self._pub("error_occurred", message=msg, source="puzzle")
        return False

    def _advance(self):
        n = self.state.tracker.collected_count()
        c = self.state.stage
        ns = None
        if n == 1 and c == STAGE_INTRO:    ns = STAGE_MIDWAY
        elif n == 2 and c == STAGE_MIDWAY: ns = STAGE_ADVANCED
        elif n == 3 and c == STAGE_ADVANCED: ns = STAGE_FINAL
        if ns:
            self.state.tracker.advance_stage(ns)
            self._pub("stage_changed", new_stage=ns)

    # T14
    def submit_final_password(self, password):
        self.state.clear_messages()
        if self.state.stage != STAGE_FINAL:
            msg = "Aun no tienes todas las pistas."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="final")
            return False
        if not password or not password.strip():
            msg = "Ingresa la contrasena final."
            self.state.set_error(msg)
            self._pub("error_occurred", message=msg, source="final")
            return False
        if password.strip().lower() == FINAL_PASSWORD:
            self.state.tracker.advance_stage(STAGE_COMPLETE)
            self.state.set_feedback("Lo lograste! El diario esta desbloqueado.")
            self._pub("game_complete", stage=STAGE_COMPLETE)
            self._pub("stage_changed", new_stage=STAGE_COMPLETE)
            return True
        msg = "Contrasena incorrecta. Revisa tus pistas."
        self.state.set_error(msg)
        self._pub("error_occurred", message=msg, source="final")
        return False

    # AYUDA
    def request_help(self):
        stage = self.state.stage
        text  = _HELP.get(stage, "Explora el telefono.")
        self._pub("help_requested", stage=stage)
        return text

    def get_puzzle_hint(self, clue_key):
        p = self.state.get_puzzle_by_clue(clue_key)
        return p.get_random_hint() if p else "Sin pistas adicionales."

    # T11
    def is_phone_locked(self):     return self.state.stage == STAGE_LOCKED
    def is_game_complete(self):    return self.state.stage == STAGE_COMPLETE
    def is_final_lock_active(self): return self.state.stage == STAGE_FINAL
    def get_stage(self):           return self.state.stage
    def get_state_summary(self):   return self.state.full_summary()

    # T10
    def get_collected_clues(self):
        out = HashMap()
        for c in self.state.tracker.all_clues():
            if c.collected:
                out.put(c.key, c.value)
        return out

    def has_clue(self, clue_key):
        return self.state.tracker.has_clue(clue_key)

    # Observer
    def subscribe(self, event_name, listener):
        self.bus.subscribe(event_name, listener)

    def unsubscribe(self, event_name, listener):
        self.bus.unsubscribe(event_name, listener)
