// https://docs.space.id/developer-guide/web3-name-sdk/sid-sdk
const SID = require('@siddomains/sidjs').default      
const SIDfunctions = require('@siddomains/sidjs')                                                                                                                                                                                
const ethers = require('ethers')                                                                                                                

let sid 

async function main(name) {
  const rpc = "https://data-seed-prebsc-1-s1.binance.org:8545/"  
  const provider = new ethers.providers.HttpProvider(rpc)
  const chainId = '97'
  sid = new SID({ provider, sidAddress: SIDfunctions.getSidAddress(chainId) })

  const address = await sid.name(name).getAddress() // 0x123                                                                                
  console.log("name: %s, address: %s", name, address)                                                                                           

}                                                                                                                                           
main("wbeth-usd.boracle.bnb")