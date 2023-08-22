import namehash from 'eth-ens-namehash'

const feedRegistrySID = 'hay-usd.boracle.bnb'
const feedRegistryNodeHash = namehash.hash(feedRegistrySID)

console.log(feedRegistryNodeHash)
