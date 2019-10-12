using ElectronProgressBars
using Logging
using LoggingExtras

global_logger(DemuxLogger(ElectronProgressBars.get_logger()))
