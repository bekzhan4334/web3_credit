const {Web3} = require('web3')

// to get the info from console
const readline = require('readline-sync');
const fs = require('fs')

async function main() {

   let web3 = new Web3('http://127.0.0.1:7545')

   let account = web3.eth.accounts.privateKeyToAccount('0xa1233a3ef1ca662874cb0468fdec21af1163e9b304db154361971543800560f8')

   const ABI = JSON.parse(fs.readFileSync(__dirname + '\\' + 'Example.abi', 'utf-8'))
   const bytecode = fs.readFileSync(__dirname + '\\' + 'Example.bin', 'utf-8')


   let myContract = new web3.eth.Contract(ABI)

   await myContract.deploy({data: bytecode, arguments: [5, 10, 'Hello']})
   .send({
    from: account.address,
    gas: 1_000_000
   })
   //.on('receipt', (receipt) => console.log(receipt))
   .then((newContractInstance) => (myContract = newContractInstance))

   // searching for function names
   const functionNames = myContract.options.jsonInterface
   .filter(interfaceItem => interfaceItem.type === "function")
   .map(interfaceItem => interfaceItem.name);
   
   // menu
   start_position: while(true){
      console.log('Choose method to call: \n')

      for(let i = 0; i < functionNames.length; i++){
         console.log( i+1 + ') ' + functionNames[i])
      }
   
      console.log((functionNames.length+1) + ') Exit')

      let n = Number(readline.question('Enter method number: '))
      let eGas
      switch(n){
         case 1:
            let adr = readline.question('Enter address: ')
            let number = readline.question('Enter number: ')
            let s = readline.question('Enter string: ')

            // gas estimator
            eGas = await myContract.methods.addToMap(adr, [number, s])
            .estimateGas({
               from: account.address,
               gas: 100_000
            })

            // sending method
            await myContract.methods.addToMap(adr, [number , s])
            .send({
               from: account.address,
               gas: eGas
            })

            
            continue start_position
         case 2:
            let size = readline.question('Enter size of the Array: ')

            eGas = await myContract.methods.init(size)
            .estimateGas({
               from: account.address,
               gas: 500_000
            })

            // sending method
            await myContract.methods.init(size)
            .send({
               from: account.address,
               gas: eeGas
            })
            .on('transactionHash', (hash) => console.log(hash))
            continue start_position
         case 3:
            // map function
            let ad = readline.question('Enter address: ')
            await myContract.methods.map(ad)
            .call({from: account.address})
            .then((result) => {
            console.log('Number: ' + result.number)
            console.log('String: ' + result.str)
            })
            continue start_position
         case 4:
            // setStr function
            let str = readline.question('Enter string: ')
            eGas = await myContract.methods.setStr(str)
            .estimateGas({
               from: account.address,
               gas: 500_000
            })

            await myContract.methods.setStr(str)
            .send({
               from: account.address,
               gas: eGas
            })
            continue start_position
         case 5:
            let x = readline.question('Enter x: ')
            let y = readline.question('Enter y: ')

            eGas = await myContract.methods.setXY(x,y)
            .estimateGas({
               from: account.address,
               gas: 100_000
            })

            await myContract.methods.setXY(x,y)
            .send({
               from: account.address,
               gas: eGas
            })
            //.on('receipt', (receipt) => console.log(receipt))
            continue start_position
         case 6:
            // str getter function
            await myContract.methods.str()
            .call({from: account.address})
            .then((result) => console.log('String: ' + result))
            continue start_position
         case 7:
            await myContract.methods.x()
            .call({from: account.address})
            .then((result) => console.log('X: ' + result))
            continue start_position
         case 8:
            await myContract.methods.y()
            .call({from: account.address})
            .then((result) => console.log('Y: ' + result))
            continue start_position
         case 9:
            break start_position
      }
   }
   


   

}

main()