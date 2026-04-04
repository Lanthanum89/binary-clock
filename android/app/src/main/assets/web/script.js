const BIT_VALUES = [8, 4, 2, 1];
const UNITS = ["hours", "minutes", "seconds"];
const STORAGE_KEY = "binary-bloom-clock-state";

const state = {
  format: "24",
  position: null,
  size: null
};

const widgetShell = document.getElementById("widgetShell");
const clockContent = document.getElementById("clockContent");
const widgetBar = document.getElementById("widgetBar");
const periodLabel = document.querySelector("[data-period-label]");
const formatButtons = document.querySelectorAll("[data-format-toggle]");
const fitToScreenButton = document.getElementById("fitToScreenButton");

const SCREEN_MARGIN = 20;
const MIN_WIDGET_WIDTH = 360;
const MIN_WIDGET_HEIGHT = 620;
const MAX_WIDGET_WIDTH = 1080;
const MAX_WIDGET_HEIGHT = 860;

let dragState = null;

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));

    if (!saved) {
      return;
    }

    if (saved.format === "12" || saved.format === "24") {
      state.format = saved.format;
    }

    if (saved.position) {
      state.position = saved.position;
    }

    if (saved.size) {
      state.size = saved.size;
    }
  } catch {
    localStorage.removeItem(STORAGE_KEY);
  }
}

function saveState() {
  const nextState = {
    format: state.format,
    position: state.position,
    size: state.size
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(nextState));
}

function createBitTiles() {
  UNITS.forEach((unit) => {
    ["tens", "ones"].forEach((digitPosition) => {
      const stack = document.querySelector(`[data-bits="${unit}-${digitPosition}"]`);

      BIT_VALUES.forEach((value) => {
        const tile = document.createElement("div");
        tile.className = "bit-tile inactive";
        tile.dataset.value = value;
        tile.dataset.digitPosition = digitPosition;
        tile.setAttribute("role", "presentation");
        stack.appendChild(tile);
      });
    });
  });
}

function applyFormatButtons() {
  formatButtons.forEach((button) => {
    const isActive = button.dataset.formatToggle === state.format;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", String(isActive));
  });
}

function updateDigitStack(unit, digitPosition, digitValue) {
  const stack = document.querySelector(`[data-bits="${unit}-${digitPosition}"]`);
  const tiles = stack.querySelectorAll(".bit-tile");
  const binary = digitValue.toString(2).padStart(BIT_VALUES.length, "0");

  tiles.forEach((tile, index) => {
    const isActive = binary[index] === "1";
    tile.classList.toggle("active", isActive);
    tile.classList.toggle("inactive", !isActive);
    tile.setAttribute("aria-label", `${unit} ${digitPosition} digit value ${tile.dataset.value} ${isActive ? "on" : "off"}`);
  });

  return binary;
}

function updateUnit(unit, value) {
  const tens = Math.floor(value / 10);
  const ones = value % 10;
  const tensBinary = updateDigitStack(unit, "tens", tens);
  const onesBinary = updateDigitStack(unit, "ones", ones);

  document.querySelector(`[data-binary-label="${unit}"]`).textContent = `${tensBinary} ${onesBinary}`;
  document.querySelector(`[data-decimal-label="${unit}"]`).textContent = String(value).padStart(2, "0");
}

function getHourValue(hours24) {
  if (state.format === "24") {
    return {
      display: hours24,
      period: "24H"
    };
  }

  const period = hours24 >= 12 ? "PM" : "AM";
  const displayHour = hours24 % 12 || 12;

  return {
    display: displayHour,
    period
  };
}

function updateClock() {
  const now = new Date();
  const hourValue = getHourValue(now.getHours());

  updateUnit("hours", hourValue.display);
  updateUnit("minutes", now.getMinutes());
  updateUnit("seconds", now.getSeconds());
  periodLabel.textContent = hourValue.period;
}

function getViewportSize() {
  return {
    width: window.innerWidth,
    height: window.innerHeight
  };
}

function getAvailableSize() {
  const viewport = getViewportSize();

  return {
    width: Math.max(MIN_WIDGET_WIDTH, viewport.width - SCREEN_MARGIN * 2),
    height: Math.max(MIN_WIDGET_HEIGHT, viewport.height - SCREEN_MARGIN * 2)
  };
}

function getShellInnerSize() {
  const shellStyles = window.getComputedStyle(widgetShell);
  const horizontalPadding = parseFloat(shellStyles.paddingLeft) + parseFloat(shellStyles.paddingRight);
  const verticalPadding = parseFloat(shellStyles.paddingTop) + parseFloat(shellStyles.paddingBottom);

  return {
    width: Math.max(0, widgetShell.clientWidth - horizontalPadding),
    height: Math.max(0, widgetShell.clientHeight - verticalPadding)
  };
}

function getFittedSize(preferredSize = {}) {
  const available = getAvailableSize();

  const width = Math.min(MAX_WIDGET_WIDTH, available.width, preferredSize.width ?? available.width);
  const height = Math.min(MAX_WIDGET_HEIGHT, available.height, preferredSize.height ?? available.height);

  return {
    width: Math.max(Math.min(width, available.width), Math.min(MIN_WIDGET_WIDTH, available.width)),
    height: Math.max(Math.min(height, available.height), Math.min(MIN_WIDGET_HEIGHT, available.height))
  };
}

function centerWidget(preferredSize) {
  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;
  const fittedSize = getFittedSize(preferredSize);
  const left = Math.max(SCREEN_MARGIN, (viewportWidth - fittedSize.width) / 2);
  const top = Math.max(SCREEN_MARGIN, (viewportHeight - fittedSize.height) / 2);

  widgetShell.style.width = `${fittedSize.width}px`;
  widgetShell.style.height = `${fittedSize.height}px`;
  widgetShell.style.left = `${left}px`;
  widgetShell.style.top = `${top}px`;

  state.position = { left, top };
  state.size = fittedSize;
}

function clampWidgetPosition(left, top) {
  const maxLeft = Math.max(SCREEN_MARGIN, window.innerWidth - widgetShell.offsetWidth - SCREEN_MARGIN);
  const maxTop = Math.max(SCREEN_MARGIN, window.innerHeight - widgetShell.offsetHeight - SCREEN_MARGIN);

  return {
    left: Math.min(Math.max(SCREEN_MARGIN, left), maxLeft),
    top: Math.min(Math.max(SCREEN_MARGIN, top), maxTop)
  };
}

function applySavedLayout() {
  if (window.innerWidth <= 860) {
    widgetShell.style.left = "0px";
    widgetShell.style.top = "0px";
    widgetShell.style.height = "auto";
    widgetShell.style.width = "100%";
    return;
  }

  if (!state.position || !state.size) {
    centerWidget();
    saveState();
    return;
  }

  const fittedSize = getFittedSize(state.size);
  widgetShell.style.width = `${fittedSize.width}px`;
  widgetShell.style.height = `${fittedSize.height}px`;
  state.size = fittedSize;

  const clamped = clampWidgetPosition(state.position.left, state.position.top);
  widgetShell.style.left = `${clamped.left}px`;
  widgetShell.style.top = `${clamped.top}px`;
  state.position = clamped;
}

function fitWidgetToScreen() {
  if (window.innerWidth <= 860) {
    return;
  }

  centerWidget(getAvailableSize());
  fitContentToShell();
  saveState();
}

function fitContentToShell() {
  if (window.innerWidth <= 860) {
    clockContent.style.transform = "scale(1)";
    return;
  }

  const shellInnerSize = getShellInnerSize();

  if (!shellInnerSize.width || !shellInnerSize.height) {
    return;
  }

  clockContent.style.transform = "scale(1)";
  clockContent.style.width = `${shellInnerSize.width}px`;

  const contentWidth = clockContent.scrollWidth;
  const contentHeight = clockContent.scrollHeight;
  const scale = Math.min(1, shellInnerSize.width / contentWidth, shellInnerSize.height / contentHeight);

  clockContent.style.transform = `scale(${scale})`;
}

function handlePointerDown(event) {
  if (window.innerWidth <= 860 || event.target.closest("button")) {
    return;
  }

  dragState = {
    offsetX: event.clientX - widgetShell.offsetLeft,
    offsetY: event.clientY - widgetShell.offsetTop
  };

  widgetShell.classList.add("is-dragging");
}

function handlePointerMove(event) {
  if (!dragState) {
    return;
  }

  const nextPosition = clampWidgetPosition(event.clientX - dragState.offsetX, event.clientY - dragState.offsetY);
  widgetShell.style.left = `${nextPosition.left}px`;
  widgetShell.style.top = `${nextPosition.top}px`;
  state.position = nextPosition;
}

function handlePointerUp() {
  if (!dragState) {
    return;
  }

  dragState = null;
  widgetShell.classList.remove("is-dragging");
  saveState();
}

function trackResize() {
  if (window.innerWidth <= 860) {
    return;
  }

  const resizeObserver = new ResizeObserver(() => {
    state.size = {
      width: Math.round(widgetShell.offsetWidth),
      height: Math.round(widgetShell.offsetHeight)
    };

    if (!dragState) {
      const clamped = clampWidgetPosition(widgetShell.offsetLeft, widgetShell.offsetTop);
      widgetShell.style.left = `${clamped.left}px`;
      widgetShell.style.top = `${clamped.top}px`;
      state.position = clamped;
    }

    fitContentToShell();
    saveState();
  });

  resizeObserver.observe(widgetShell);
}

function setupEvents() {
  formatButtons.forEach((button) => {
    button.addEventListener("click", () => {
      state.format = button.dataset.formatToggle;
      applyFormatButtons();
      updateClock();
      saveState();
    });
  });

  fitToScreenButton.addEventListener("click", fitWidgetToScreen);
  widgetBar.addEventListener("pointerdown", handlePointerDown);
  window.addEventListener("pointermove", handlePointerMove);
  window.addEventListener("pointerup", handlePointerUp);
  window.addEventListener("resize", () => {
    applySavedLayout();
    fitContentToShell();
    saveState();
  });
}

loadState();
createBitTiles();
applyFormatButtons();
applySavedLayout();
trackResize();
setupEvents();
updateClock();
fitContentToShell();
setInterval(updateClock, 1000);