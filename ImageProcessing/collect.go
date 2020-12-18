package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

func main() {
	fetchResultData("long.ma.cancel-booking-metrics")
	fetchResultData("long.ma.reserve-booking-metrics")
	fetchResultData("long.ma.notify-booking-metrics")
	fetchResultData("long.ma.confirm-booking-metrics")
	fetchResultData("long.ma.capture-stripe-metrics")
	fetchResultData("long.ma.charge-stripe-metrics")
	fetchResultData("long.ma.refund-stripe-metrics")
	fetchResultData("long.ma.collect-payment-metrics")
	fetchResultData("long.ma.refund-payment-metrics")
	fetchResultData("long.ma.loyalty-get-metrics")
	fetchResultData("long.ma.loyalty-ingest-metrics")
}

func fetchResultData(tableName string) {
	file, err := os.OpenFile(fmt.Sprintf("%s.csv", tableName), os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0666)
	if err != nil {
		log.Fatal("Cannot create data file", err)
	}
	defer file.Close()
	writer := csv.NewWriter(file)
	defer writer.Flush()
	writer.Write([]string{
		"duration",
		"maxRss",
		"fsRead",
		"fsWrite",
		"vContextSwitches",
		"ivContextSwitches",
		"userDiff",
		"sysDiff",
		"rss",
		"heapTotal",
		"heapUsed",
		"external",
		"elMin",
		"elMax",
		"elMean",
		"elStd",
		"bytecodeMetadataSize",
		"heapPhysical",
		"heapAvailable",
		"heapLimit",
		"mallocMem",
		"netByRx",
		"netPkgRx",
		"netByTx",
		"netPkgTx",
	})
	sess := session.Must(session.NewSession())
	dynamoClient := dynamodb.New(sess, aws.NewConfig().WithRegion("eu-west-1"))
	dynamoClient.ScanPages(&dynamodb.ScanInput{
		TableName: &tableName,
	}, func(result *dynamodb.ScanOutput, lastPage bool) bool {
		for _, response := range result.Items {
			writer.Write([]string{
				*response["duration"].N,
				*response["maxRss"].N,
				*response["fsRead"].N,
				*response["fsWrite"].N,
				*response["vContextSwitches"].N,
				*response["ivContextSwitches"].N,
				*response["userDiff"].N,
				*response["sysDiff"].N,
				*response["rss"].N,
				*response["heapTotal"].N,
				*response["heapUsed"].N,
				*response["external"].N,
				*response["elMin"].N,
				*response["elMax"].N,
				*response["elMean"].N,
				*response["elStd"].N,
				*response["bytecodeMetadataSize"].N,
				*response["heapPhysical"].N,
				*response["heapAvailable"].N,
				*response["heapLimit"].N,
				*response["mallocMem"].N,
				*response["netByRx"].N,
				*response["netPkgRx"].N,
				*response["netByTx"].N,
				*response["netPkgTx"].N,
			})
		}
		writer.Flush()
		return !lastPage
	})
}
