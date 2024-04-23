extension Extensions on int {
  String toState() {
    final int state = this;
    String sState = '';
    switch (state) {
      case 0:
        sState = 'STATE_QUEUED';
      case 1:
        sState = 'STATE_STOPPED';
      case 2:
        sState = 'STATE_DOWNLOADING';
      case 3:
        sState = 'STATE_COMPLETED';
      case 4:
        sState = 'STATE_FAILED';
      case 5:
        sState = 'STATE_REMOVING';
      case 7:
        sState = 'STATE_RESTARTING';
    }
    return sState;
  }
}
