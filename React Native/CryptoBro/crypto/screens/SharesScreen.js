import React, { useState, useEffect } from 'react';
import { Text, View, StyleSheet } from "react-native"
import { Dimensions } from "react-native";
import { LineChart } from "react-native-chart-kit";
import DropDownPicker from 'react-native-dropdown-picker';
import bitcoinData from './../assets/bitcoin_currency_data_365.json'
import dashData from './../assets/dash_currency_data_365.json'
import ethereumData from './../assets/ethereum_currency_data_365.json'
import stellarData from './../assets/stellar_currency_data_365.json'
import xprData from './../assets/xpr_currency_data_365.json'

export default function SharesScreen(){

    const [trendColor, setTrendColor] = useState('black');

    const [open, setOpen] = useState(false);
    const [value, setValue] = useState(null);
    const [items, setItems] = useState([
        {label: 'Bitcoin', value: 'bitcoin'},
        {label: 'Ethereum', value: 'ethereum'},
        {label: 'XPR', value: 'xpr'},
        {label: 'Dash', value: 'dash'},
        {label: 'Stellar', value: 'stellar'},
    ]);
    const [dataValues, setDataValues] = useState([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,])
    const [currentTrend, setCurrentTrend] = useState('')

    //const [data, setData] = useState([]);
    const [labels, setLabels] = useState([])
    const [dataBitcoin, setDataBitcoin] = useState([])
    const [dataEthereum, setDataEthereum] = useState([])
    const [dataXPR, setDataXPR] = useState([])
    const [dataDash, setDataDash] = useState([])
    const [dataStellar, setDataStellar] = useState([])

    const putValueForDia = async () => {

        console.log('PutValueForDia Called')
        if(value == 'bitcoin'){
            setDataValues(dataBitcoin)
            getCurrentTrend(dataBitcoin);
        } else if(value == 'ethereum') {
            setDataValues(dataEthereum)
            getCurrentTrend(dataEthereum);
        } else if(value == 'xpr'){
            setDataValues(dataXPR)
            getCurrentTrend(dataXPR);
        } else if(value == 'dash'){
            setDataValues(dataDash)
            getCurrentTrend(dataDash);
        } else if(value == 'stellar'){
            setDataValues(dataStellar)
            getCurrentTrend(dataStellar);
        } else {
            setDataValues([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
        }

        
    }
    
    const getCurrentTrend = (dataArray) => {
        if(dataArray.at(dataArray.length - 1) > dataArray.at(dataArray.length - 2)){
            console.log('Second Last: ', dataArray.at(dataArray.length - 2), '; Last: ', dataArray.at(dataArray.length - 1))
            setCurrentTrend('Rising')
            setTrendColor('green')
        } else if(dataArray.at(dataArray.length - 1) < dataArray.at(dataArray.length - 2)){
            console.log('Second Last: ', dataArray.at(dataArray.length - 2), '; Last: ', dataArray.at(dataArray.length - 1))
            setCurrentTrend('Falling')
            setTrendColor('red')
        } else {
            setCurrentTrend('Neutral')
            setTrendColor('black')
        }
    }
    
    useEffect(() => {
        const loadData = () => {

            var bitcoinAsArray = JSON.parse(JSON.stringify(bitcoinData))
            var ethereumAsArray = JSON.parse(JSON.stringify(ethereumData))
            var dashAsArray = JSON.parse(JSON.stringify(dashData))
            var xprAsArray = JSON.parse(JSON.stringify(xprData))
            var stellarAsArray = JSON.parse(JSON.stringify(stellarData))


            var tempLabels = []
            bitcoinAsArray.forEach((el) => {
                tempLabels.push(el.Date)
            })
            setLabels(tempLabels)

            var tempBitcoin = []
            bitcoinAsArray.forEach((el) => {
                tempBitcoin.push(el.Currency_Value)
            })
            setDataBitcoin(tempBitcoin)

            var tempDash = []
            dashAsArray.forEach((el) => {
                tempDash.push(el.Currency_Value)
            })
            setDataDash(tempDash)

            var tempXPR = []
            xprAsArray.forEach((el) => {
                tempXPR.push(el.Currency_Value)
            })
            setDataXPR(tempXPR)

            var tempStellar = []
            stellarAsArray.forEach((el) => {
                tempStellar.push(el.Currency_Value)
            })
            setDataStellar(tempStellar)

            var tempEthereum = []
            ethereumAsArray.forEach((el) => {
                tempEthereum.push(el.Currency_Value)
            })
            setDataEthereum(tempEthereum)
        }

        loadData()
        
    }, [])

    useEffect(() => {
        putValueForDia();
        
    }, [value])
    
    return(
        <View style={styles.wholeView}>
            <DropDownPicker
                open={open}
                value={value}
                items={items}
                setOpen={setOpen}
                setValue={setValue}
                setItems={setItems}
                style={styles.dropdown}
            />

            <Text style={styles.currentValueText}> Current Value: {dataValues.at(dataValues.length - 1)}</Text>

            <LineChart
                data={{
                    
                    datasets: [
                        {
                            data: dataValues,
                        },
                        {
                            data: [0],
                        },
                        {
                            data: [2],
                        },
                    ]
                }}
                width={Dimensions.get("window").width} // from react-native
                height={220}
                yAxisLabel="$"
                yAxisSuffix="k"
                fromZero={true}
                hidePointsAtIndex={[0]}
                withVerticalLines={false}
                withDots={false}
                yAxisInterval={1} // optional, defaults to 1
                onDataPointClick={(pointData) => {
                    setSelcetedDetailValue(pointData.value)
                }}
                
                chartConfig={{
                    backgroundColor: "#000000",
                    //backgroundGradientFrom: "#fb8c00",
                    //backgroundGradientTo: "#ffa726",
                    decimalPlaces: 2, // optional, defaults to 2dp
                    color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
                    labelColor: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
                    style: {
                        borderRadius: 16
                    },
                    propsForDots: {
                        r: "4",
                        strokeWidth: "2",
                        stroke: "#ffa726"
                    }
                }}
                style={{
                    marginVertical: 8,
                    borderRadius: 16,
                    marginRight: 20,
                    marginLeft: 20
                }}
            />
            <Text style={[styles.selectedValueText, {color: trendColor}]}>Trend: {currentTrend}</Text>
        </View>
        
    )
}

const styles = StyleSheet.create({
    lineChart: {
        flex: 1, // The View will fill the whole screen
        alignItems: 'center', // Center children horizontally
        width: '100%',
        
    },
    wholeView: {
        flex: 1,
        alignItems: 'center',
        marginLeft: 20,
        width: Dimensions.get("window").width - 40,
    },
    dropdown: {
        marginTop: 5,
    },
    currentValueText: {
        padding: 20,
        fontSize: 25,
        fontWeight: 'bold'
    },
    selectedValueText: {
        padding: 20,
        fontSize: 25,
        fontWeight: 'bold'
    }
})