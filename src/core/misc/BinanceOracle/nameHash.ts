import namehash from 'eth-ens-namehash'

const feedRegistrySID = 'fr.boracle.bnb'
const feedRegistryNodeHash = namehash.hash(feedRegistrySID)

console.log(feedRegistryNodeHash)