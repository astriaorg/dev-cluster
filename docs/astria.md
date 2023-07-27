# [Astria](https://www.astria.org/): Decentralized by Default
 - [The Astria dev-cluster](#the-astria-dev-cluster)
 - [Architecture](#architecture)
    - [Users](#users)
    - [Rollups](#rollups)
    - [Composer (under construction)](#composer-under-construction)
    - [The Shared Sequencer](#the-shared-sequencer)
    - [Relayer](#relayer)
    - [Data Availability](#data-availability)
    - [Conductor](#conductor)
 - [Running the Cluster](#running-the-cluster)
    - [Installation](#installation)
    - [Deployment](#deployment)
    - [Faucet and Block Explorer](#faucet-block-explorer-and-test-data)
    - [Multiple Rollups](#run-multiple-rollups)
    - [What's Going on Under the Hood?](#whats-going-on-under-the-hood)
 - [Summary](#summary)

## The Astria [dev-cluster](https://github.com/astriaorg/dev-cluster)
The Astria Shared Sequencer Network replaces centralized sequencers, allowing many rollups to share a single decentralized network of sequencers that’s simple and permissionless to join. This shared sequencer network provides out-of-the-box censorship resistance, fast block confirmations, and atomic cross-rollup composability – all while retaining each rollup’s sovereignty.

The Astria dev-cluster is the collective stack of all of Astria's components packaged together using Kubernetes. Although we refer to Astria as just a shared sequencer, it is composed of many smaller components that each fulfill a specific function to enable the final shared sequencing functionality. Instead of users and developers having to keep track of and manage all the individual components, the dev-cluster is built to make locally deploying and testing Astria as simple and robust as possible. 

This document outlines what each of the components do, and provides some basic instructions for running the dev cluster yourself.

## Architecture
If you have seen any of [Josh's](https://twitter.com/Jskybowen) recent presentations about Astria, you will likely have seen this image:
![Astria at a high level](/images/astria-high-level.png "Astria at a high level")
This shows the basic structure of what a shared sequencer is but purposely doesn't dive into any of the details of Astria to keep things simple. However, Astria's general architecture does break down into the basic items shown above.

When expanded to show more detail, Astria's architecture looks like this:
![Astria Architecture](/images/astria-architecture.png "Astria Architecture")
Given the diagram above, we can take a look at each of the components that make up Astria in more detail.

### Users
One of the goals of Astria is to improve the current user experience by having fast finality, Cross Rollup Composability, decentralization, and  sovereignty all in one place and out of the box. There are no hard requirements for rollups to change how their current users interact with what they offer, but additional RPCs would need to be implemented by the rollup in order for their users to take advantage of some of those features.

### Rollups
Astria is designed for permissionless rollup integration and takes advantage of lazy shared sequencing. This means that rollup developers have total sovereignty over their own execution state and can swap out sequencing layers without fear of being locked in. See the [Introduction to Astria](https://blog.astria.org/introducing-astria/) blog post for more details.

When developing a rollup that utilizes Astria, there are only two interfaces that you need to satisfy:
1. Rollup <-> Composer: 
    - For transaction submissions.
2. Rollup <-> Conductor: 
    - For receiving data from the sequencing network.

The [Composer](#composer) and [Conductor](#conductor) are explained in more detail in future sections.

![Astria Rollup](/images/astria-rollups "A rollup deployed on Astria")
These interfaces utilize [gRPC](https://grpc.io/) to allow for rollup developers to use a wide range of languages for their application. Check out the [astria-protos](https://github.com/astriaorg/astria/tree/main/crates/astria-proto) repo for specific implementation details. This ultimately results in tremendous freedom for developers, giving them control over their own execution and state without needing to worry about the underlying sequencer and data availability infrastructure.

The current dev-cluster deploys a fork of [Geth](https://github.com/astriaorg/go-ethereum) as an EVM rollup. 

### Composer (under construction)
In the current dev-cluster, the Composer is not yet implemented or included. As of this writing, the Geth rollup mentioned in the previous section simply sends transactions directly to the sequencer network. The Composer will ultimately act as an intermediate component between any given rollup and the sequencer.

The Composer is an in-house abstraction over the potential actors in an MEV market. It contains naive implementations of the roles that a searcher and a builder will fulfill, with the intention of having working examples that economically incentivized third parties can use as a starting point for their own implementations. The abstraction serves the goal of acting as a forcing function on our architecture design by stubbing out the roles and requiring other components to interact with them through an interface.
While a real searcher implementation would create profit-generating bundles of rollup transactions and submit them to a builder, the Composer implementation simply bundles every rollup transaction it receives into a sequence transaction and forwards it to the composer's builder. Similarly, while a real builder implementation would run a profit-generating auction, the composer implementation will simply run a FIFO queue that will add all the sequence transactions it receives and submits a block to the sequencer's proposer.

### The Shared Sequencer
The Astria Shared Sequencer is a decentralized network of nodes utilizing CometBFT that come to consensus on an ordered set of transactions (ie. it is a blockchain). The unique feature of the sequencer is that the transactions it includes are not executed (lazy sequencing), and are destined for another execution engine (ie. a rollup). This excludes “sequencer native” transactions, such as transfers of tokens within the sequencer chain. Transactions from any given rollup are only ordered on the sequencer, not executed.

The sequencer can optionally act as a “validator”, meaning it actively participates in the production and finalization of new blocks.

### Relayer
The Relayer's responsibility is to take validated blocks from the sequencer and pass them along to both the Conductor and the DA layer. Because the sequencers block times are much faster than those of the DA, the relayer also collects a queue of sequencer blocks before wrapping them for submission to DA.

The individual sequencer blocks sent to the Conductor enable fast finality for an improved UX and also act as soft commits for the execution layer. The collections of blocks sent to the DA layer are used as a source of truth and are ultimately pulled from the DA to be used as firm commits for finality in the rolllups.

### Data Availability
The dev-cluster uses [Celestia](https://github.com/celestiaorg) as the data availability layer and is the ultimate destination of all data that has been ordered by the sequencer network. Once written to Celestia, the transaction order is considered final and it is where all data will be pulled from if you need to spin up a new rollup node.

### Conductor
The Conductor is the second to last component in the data lifecycle for transaction in the Astria stack, with the rollup itself being both the start and finish for any given transaction. Each rollup runs its own instance of the Conductor. The Conductor's responsibility is to ingest the soft commit sequencer blocks from the relayer and pull in the firm commit data from Celestia to pass transaction data to be executed on the rollup and update the canonical chain.
The Conductor is effectively stateless but does ephemerally store some information about the blocks it has seen and passed on to be executed. It primarily filters the transactions that are relevant to a given rollup out of the sequencer blocks for execution. The data that it does store is for sending commitment updates to the rollup.
As mentioned in the Relayer section above, any data received by the Conductor directly from the Relayer is considered a soft commit and is filtered and sent to the rollup for execution and for setting that block to "safe". The Conductor regularly polls Celestia for new data and when it sees the same blocks in Celestia that it has already seen from the Relayer, it sends a firm commit message to the rollup to update that block to "finalized."

And that's it! Hopefully you now have a better understanding of what is actually happening under the hood and what the purpose of each component of Astria is used for. Now it's time to run it yourself!

## Running the Cluster

### Installation
You will need to pull both the [dev-cluster](https://github.com/astriaorg/dev-cluster) and [astria-web3](https://github.com/astriaorg/astria-web3) repos from our github.

Install the necessary dependencies and tools listed for each repo.

### Deployment
To deploy the full dev-cluster, open a terminal in the dev-cluster directory and run the command: 
```
just deploy-all-local
```

This may take a minute or two if this the first time you are deploying as quite a few containers need to be downloaded. Once the command completes, all elements of the dev-cluster will be up and running including a geth rollup, faucet and block explorer. The default deploy only spins up a single rollup but have no fear we'll get to multiple rollups shortly.

### Faucet, Block Explorer, and Test Data
With the dev-cluster running, you can access the block explorer and faucet by opening a couple new windows in your browser and going to to the following urls.
For the block explorer:
```
http://blockscout.astria.localdev.me/
```
For the faucet:
```
http://faucet.astria.localdev.me/
```

You can copy and paste a wallet address on the faucet page and give yourself 1 RIA. 

To test out the block explorer, open a terminal in the astria-web3 repo you downloaded earlier and navigate to the `packages/evm-test-data/` and run the following command:
```
just generate-transactions
```
You can now go back to your browser and pull up the block explorer and you will now see transactions and blocks getting created in real time.

But wait... what about 

### Run Multiple Rollups
As Astria we believe strongly that deploying a rollup should be as easy as deploying a smart contract. The dev-cluster shows this is indeed possible.

Navigate back to the dev-cluster repo and run the following command with your own rollup name and network id:
**NOTE:** The default rollup name and network id are `astria` and `912559`. When deploying your second rollup we recommend you use a different name and number.
```
just deploy-rollup <rollup_name> <network_id>
```
As before it will take a moment for everything to spin up, but in the meantime keep the the rollup name and network id handy and navigate back to your browser and open a new window with the following url, replacing `rollup_name` with the name you just used to deploy your new rollup:
```
http://blockscout.<rollup_name>.localdev.me/
```
Once everything has spin up you will see a new block explorer for your new rollup.

You can now deploy transaction to that rollup as well independent from the first!
In the `evm-test-data` directory open a new terminal and run the following:
```
just generate-transactions <rollup_name> <network_id>
```
As before, this command will deploy test transaction data to your new rollup.
You can also go back to your other terminal window for the test data deployment on the default rollup and rerun `just generate-transactions` command. If you switch back and forth between the default block explorer window and your new rollup window, you will see transactions showing up on each rollup independently!

You may be asking, "What are the limitations here? How many rollups can I deploy?" In short, as many as your hardware can handle! You just need to pick different rollup names and network ids.

### What's Going on Under the Hood?
One last thing to mention is what is actually happening when you deploy a new rollup in the dev-cluster. When you you deploy a new rollup the only new containers that are getting spun up in the cluster are a new rollup node, a conductor, block explorer, and faucet. Only one instance of the shared sequencer and the DA layer remain running and the transactions from all the rollups are collectively getting run though those networks. This can be shown in the following diagram:
![Running multiple rollups using Astria](/images/multiple-rollup.png "Running multiple rollups using Astria")

## Summary
Hopefully this document helped shed some light on the inner workings of the Astria dev-cluster. Check us out on [Twitter](https://twitter.com/AstriaOrg), [github](https://github.com/astriaorg), and our [website](stria.org).
