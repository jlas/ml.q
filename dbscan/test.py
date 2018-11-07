'''
Generate dummy data, and compare output from scikit-learn's DBSCAN.

Example code based on:
  http://scikit-learn.org/stable/auto_examples/cluster/plot_dbscan.html#sphx-glr-auto-examples-cluster-plot-dbscan-py

Run with pytest, e.g.:

    py.test test.py
'''

import os
import shutil
import subprocess

from sklearn.cluster import DBSCAN
from sklearn.datasets.samples_generator import make_blobs
from sklearn.preprocessing import StandardScaler
import pandas as pd


EPS = .1
MIN_SAMPLES = 3


def test_compare():
    '''Compare result of our DBSCAN to scikit-learn
    '''

    # Make temp directory for dumping intermediate files
    os.mkdir('tmp')

    # Generate sample data
    centers = [[1, 1], [-1, -1], [1, -1], [-3, 3], [3, 3]]
    X, _ = make_blobs(
        n_samples=1000, centers=centers, cluster_std=0.3, random_state=0)
    X = StandardScaler().fit_transform(X)

    # Write sample data
    pd.DataFrame(X).to_csv('tmp/sample_data.csv', header=None, index=False)

    # Compute our DBSCAN
    # Run in a python subprocess which sends a few lines of q into the stdin
    # of a q interpreter. Assumed to run in same directory as dbscan.q module.
    subprocess.run(f'''echo ' \
system "l dbscan.q"; \
t:value each flip `x`y!("FF";",") 0: `$"tmp/sample_data.csv"; \
d:dbscan[t;{MIN_SAMPLES};{EPS}]; \
(`:tmp/q.csv) 0: .h.tx[`csv;flip enlist[`labels]!enlist[d]]' | \
$QHOME/m32/q -q''', shell=True, stdout=subprocess.DEVNULL)
    qlabels = pd.read_csv('tmp/q.csv')['labels']

    # Compute scikit-learn's DBSCAN
    db = DBSCAN(eps=EPS, min_samples=MIN_SAMPLES).fit(X)
    pylabels = db.labels_

    # Compare
    assert (qlabels == pylabels).all()

    # Cleanup temp directory
    shutil.rmtree('tmp')
