import namehash from 'eth-ens-namehash'

const feedRegistrySID = 'wbeth-usd.boracle.bnb'
const feedRegistryNodeHash = namehash.hash(feedRegistrySID)

console.log(feedRegistryNodeHash)