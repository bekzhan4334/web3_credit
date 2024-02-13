const fs = require('fs')
const solc = require('solc')
const readline = require('readline-sync')


function myCompiler(solc, fileName, contractName, contractCode){
    // настраиваем структуру input для компилятора
    let input = {
        language: 'Solidity',
        sources: {
            [fileName]: {
            content: contractCode
        }
        },
        settings: {
            outputSelection: {
                '*': {
                    '*': ['*']
                }
            }
        }
    }
    
    let output = JSON.parse(solc.compile(JSON.stringify(input)));
    
    // console.log("Compilation result: ", output.contracts[fName])

    let ABI = output.contracts[fName][contractName].abi
    let bytecode = output.contracts[fName][contractName].evm.bytecode.object
    // console.log(ABI)
    // console.log(bytecode)

    fs.writeFileSync(__dirname + '\\' + contractName + '.abi', JSON.stringify(ABI))
    fs.writeFileSync(__dirname + '\\' + contractName + '.bin', bytecode)
}

let fName = readline.question('Enter file name: ')
let cName = readline.question('Enter contract name: ')

// считаем код контракта из файла
let cCode = fs.readFileSync(__dirname + '\\contracts' + '\\' + fName, 'utf-8')
// console.log(cCode)


try{
    myCompiler(solc, fName, cName, cCode)
} catch(err){
    console.log(err)

    // let solcx = solc.setupMethods(require('./soljson-v0.8.15+commit.e14f2714'))

    let compileVersion = "v0.8.15+commit.e14f2714"
    solc.loadRemoteVersion(compileVersion, (err, solcSnapshot) => {
        if(err){
            console.log(err)
        }else{
            myCompiler(solcSnapshot, fName, cName, cCode)
        }
    })
}
