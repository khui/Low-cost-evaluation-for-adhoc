START=$(date +%s.%N)
#incrementalpool trecpool
directory=/scratch/GW/pool0/khui/result/2stagelowcost/comparativestd/pooling/trecpool
tmpdir=/scratch/GW/pool0/khui/tmp/`basename $directory`
qrelfs=$directory/qrels
directorytojud=$(find $qrelfs -name "*.oqrel" -printf "%h\n" | sort -u)
outdir=$directory/evals
echo "current pid:" $$

trecrunfolder=/GW/D5data-2/khui/trecrun/adhoc/normrun30qrel
original=/GW/D5data-2/khui/qrel/completeqrel/adhocquery
treceval=/home/khui/workspace/evaltool/trec_eval.9.0


for measure in tmap indap infap bpref
do
	if [[ -d "$outdir/$measure" ]];
	then
		echo "deleting exist folder $outdir/$measure"
		rm -rf $outdir/$measure
	fi
	mkdir -p "$outdir/$measure"
done

if [[ -d "$tmpdir" ]]
then
	echo "deleting exist folder $tmpdir"
	rm -rf $tmpdir
fi
mkdir -p $tmpdir

treceval(){
	# 1:qrel, 2:run 3:output
	# output: map P@20 R@20
	runname=$(head -1 $2 |awk '{print $6}')
	cd $treceval
	map=$(./trec_eval -m map $1 $2 | awk '{print $3}')
	indmap=$(./trec_eval -J -m map $1 $2 | awk '{print $3}')
	infmap=$(./trec_eval -m infAP $1 $2 | awk '{print $3}')
	bpref=$(./trec_eval -m bpref $1 $2 | awk '{print $3}')
	# output: runname, ndcg@20, err@20
#	measures=$(./gdeval.pl -c -k 20 $1 $2  | grep "amean" | awk -F, '{print $3" "$4}')
	echo $runname" "$map >> "$outdir/tmap/$3"
	echo $runname" "$indmap >> "$outdir/indap/$3"
	echo $runname" "$infmap >> "$outdir/infap/$3"
	echo $runname" "$bpref >> "$outdir/bpref/$3"
}

pidarray=()
# predict evaluation with trec setting
for qreld in $directorytojud;
do
	percent=$(echo $qreld|awk -F/ '{print $(NF)}')
	#sid=$(echo $qreld|awk -F/ '{print $NF}')
	for year in 09 10 11 12
	do
		qrelname=$year"-"$percent
		qrelf=$(echo $tmpdir/$qrelname)
		if [ $year -eq 09 ]
		then
			(
			for qid in {1..50}
			do
				if [ -e $qreld/$qid.bqrel ]
				then
					cat $qreld/$qid.bqrel | sort -u
				fi
			done
			) >> $qrelf
		elif [ $year -eq 10 ]
		then
			(
			for qid in {51..100}
			do
				if [ -e $qreld/$qid.bqrel ]
				then
					cat $qreld/$qid.bqrel | sort -u
				fi
			done
			) >> $qrelf
		elif [ $year -eq 11 ]
		then
			(
			for qid in {101..150}
			do
				if [ -e $qreld/$qid.bqrel ]
				then
					cat $qreld/$qid.bqrel | sort -u
				fi
			done
			) >> $qrelf
		elif [ $year -eq 12 ]
		then
			(
			for qid in {151..200}
			do
				if [ -e $qreld/$qid.bqrel ]
				then
					cat $qreld/$qid.bqrel | sort -u
				fi
			done
			) >> $qrelf
		fi
		(
			for trecrun in `ls $trecrunfolder/$year`;
			do
				#ndeval for the original list
				treceval "$qrelf"  "$trecrunfolder/$year/$trecrun" \
					"${qrelname}" &
			done
			wait
			echo $qrelname done
		)
	done
done
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "$year finished: "$DIFF
