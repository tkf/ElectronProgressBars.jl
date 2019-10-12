using ElectronProgressBars

ElectronProgressBars._gset_progress(0.0, title="main")
ElectronProgressBars._gset_progress(0.1, :sub, title="main sub")
ElectronProgressBars._gset_progress(0.8, :subsub, title="main sub sub")

ElectronProgressBars._gset_progress(0.1, title="bg", taskid=UInt64(2))
ElectronProgressBars._gset_progress(0.9, :sub; title="bg sub", taskid=UInt64(2))
